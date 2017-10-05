import React from "react";
import PropTypes from "prop-types";
import Container from "muicss/lib/react/container";

import {Board} from "./board";
import {CaptureGrid} from "./capture-grid";
import {Scoreboard} from "./scoreboard";
import {ColorSetupSelect} from "./color-setup-select";
import {PieceSelectGrid} from "./piece-select-grid";
import {ErrorElement} from "./error-element";

import {BoardSetupState} from "../models/board-setup-state";
import {DisplayState} from "../models/display-state";
import {SquareSelectionState} from "../models/square-selection-state";
import {GameState} from "../models/game-state";
import {AmbiguousMoveState} from "../models/ambiguous-move-state";

import GameService from "../services/game-service";
import {getMoveObjectForPieceMove, getMoveObjectForPlacePiece} from "../factories/move-factory";


class Game extends React.Component {
    constructor() {
        super();
        this.gameState = new GameState();
        this.boardSetupState = new BoardSetupState();
        this.displayState = new DisplayState();
        this.squareSelectionState = new SquareSelectionState();
        this.ambiguousMoveState = new AmbiguousMoveState();

        this.state = {
            gameState: this.gameState,
            boardSetupState: this.boardSetupState,
            displayState: this.displayState,
            squareSelectionState: this.squareSelectionState,
            ambiguousMoveState: this.ambiguousMoveState
        };
    }

    componentDidMount() {
        this.gameService = new GameService(this.props.httpService);
        this.gameUuid = this.props.gameUuid;
        this.start();
    }

    start() {
        this.pollGameState();
    }

    pollGameState() {
        this.retrieveNewGameState();
        setTimeout(() => this.pollGameState(), 5000);
    }

    retrieveNewGameState() {
        this.gameService.getGameByUuid(this.gameUuid).then(
            (gameResponse) => {
                if (gameResponse.lastMove != this.gameState.lastMove) {
                    this.gameState.updateFromApiResponse(gameResponse);
                    this.squareSelectionState.clear();
                    this.ambiguousMoveState.clear();

                    if (this.gameState.inBoardSetupMode()) {
                        this.boardSetupState.updateFromColorsSettingUp(this.gameState.getColorsSettingUp());
                    }

                    this.setState({
                        gameState: this.gameState,
                        boardSetupState: this.boardSetupState,
                        displayState: this.displayState,
                        squareSelectionState: this.squareSelectionState,
                        ambiguousMoveState: this.ambiguousMoveState
                    });
                }
            }
        );
    }

    handleColorSetupSelect(colorSelected) {
        this.boardSetupState.setUpBoard(colorSelected);
        this.squareSelectionState.clear();
        this.setState({
            squareSelectionState: this.squareSelectionState,
            boardSetupState: this.boardSetupState
        });
    }

    handleBoardClick(square) {
        if (square == null) {
            return;
        }

        if (this.gameState.inBoardSetupMode()) {
            this.handleBoardClickInSetupMode(square);
        } else if (this.squareSelectionState.anySquareSelected()) {
            this.handleClickWhilePieceSelected(square);
        } else if (this.gameState.hasPieceOnSquare(square)) {
            this.handleClickOnPieceSquareNothingSelected(square);
        }
    }

    handleBoardClickInSetupMode(square) {
        if (this.gameState.hasPieceOnSquare(square)) {
            return;
        }

        if (this.squareSelectionState.isSquareSelected(square)) {
            this.squareSelectionState.clear();
            this.ambiguousMoveState.clear();
        } else if (this.gameState.squareNeedsPiecePlaced(square)) {
            this.squareSelectionState.setSelected(square);
        }

        this.setState({squareSelectionState: this.squareSelectionState});
    }

    shouldHandleAsDisambiguatingCaptureSelection(square) {
        return (
            this.ambiguousMoveState.isAmbiguousDestinationSelected() &&
            this.ambiguousMoveState.isDisambiguatingCaptureForSelectedSquare(square)
        );
    }

    shouldDeactivateDisambiguatingCaptureSelection(square) {
        return (
            this.ambiguousMoveState.isAmbiguousDestinationSelected() &&
            this.ambiguousMoveState.getSelectedAmbiguousDestination() == square
        );
    }

    handleClickWhilePieceSelected(square) {
        if (this.squareSelectionState.isSquareSelected(square)) {
            this.handleClickOnSelectedSquare();
        } else if (this.shouldDeactivateDisambiguatingCaptureSelection(square)) {
            this.ambiguousMoveState.selectAmbiguousDestination(null);
            this.setState({ambiguousMoveState: this.ambiguousMoveState});
        } else if (this.shouldHandleAsDisambiguatingCaptureSelection(square)) {
            this.handleClickAmbiguousDestinationSelected(square);
        } else if (this.squareSelectionState.isSquarePossibleMove(square)) {
            this.handleClickOnPossibleMoveSquare(square);
        } else if (this.gameState.hasPieceOnSquare(square)) {
            this.squareSelectionState.clear();
            this.ambiguousMoveState.clear();
            this.handleClickOnPieceSquareNothingSelected(square);
        }
    }

    handleClickOnSelectedSquare() {
        this.squareSelectionState.clear();
        this.ambiguousMoveState.clear();
        this.setState({squareSelectionState: this.squareSelectionState});
    }

    handleClickAmbiguousDestinationSelected(square) {
        let movePieceMove = getMoveObjectForPieceMove(
            this.squareSelectionState.getSelected(),
            this.ambiguousMoveState.getSelectedAmbiguousDestination(),
            square
        );

        this.gameService.makeMove(this.gameUuid, movePieceMove).then(() => this.retrieveNewGameState());
    }

    handleClickOnPossibleMoveSquare(square) {
        if (this.ambiguousMoveState.isAmbiguousDestination(square)) {
            this.ambiguousMoveState.selectAmbiguousDestination(square);
            this.setState({ambiguousMoveState: this.ambiguousMoveState});
        } else {
            let movePieceMove = getMoveObjectForPieceMove(this.squareSelectionState.getSelected(), square);
            this.gameService.makeMove(this.gameUuid, movePieceMove).then(() => this.retrieveNewGameState());
        }
    }

    handleClickOnPieceSquareNothingSelected(square) {
        let  piece = this.gameState.getPieceOnSquare(square);

        if (piece.color != this.gameState.currentTurn) {
            return;
        }

        this.gameService.getPossibleMoves(this.gameUuid, square).then(
            (possibleMoveResponse) => {
                possibleMoveResponse.possibleMoves.forEach(possibleMove => {
                    this.squareSelectionState.addPossibleMove(possibleMove.destinationSquare);

                    if (possibleMove.hasOwnProperty("captures")) {
                        possibleMove.captures.forEach(possibleCapture => {
                            this.squareSelectionState.addPossibleCapture(possibleCapture.square);
                        });
                    }
                });

                possibleMoveResponse.ambiguousMoves.forEach(ambiguousMove => {
                    this.ambiguousMoveState.addAmbiguousMove(
                        ambiguousMove.destinationSquare,
                        ambiguousMove.disambiguatingCaptures
                    );
                });

                this.squareSelectionState.setSelected(square);
                this.setState({squareSelectionState: this.squareSelectionState});
            }
        );
    }

    handlePlacePieceSelection(piece) {
        if (!this.squareSelectionState.anySquareSelected()) {
            return;
        }

        let placeMove = getMoveObjectForPlacePiece(this.squareSelectionState.getSelected(), piece);
        this.gameService.makeMove(this.gameUuid, placeMove).then(() => this.retrieveNewGameState());
    }

    render() {
        return (
            <Container className="game-panel" fluid={true}>
                <ErrorElement error={this.props.error}/>

                <div className="row">
                    <Scoreboard gameState={this.state.gameState}/>
                </div>

                <div className="row">
                    <Board clickHandler={this.handleBoardClick.bind(this)} {...this.state}/>
                    <div className="content-block mui-col-md-4 mui-col-sm-12">
                        <div className="row">
                            <CaptureGrid gameState={this.state.gameState} captureColor="WHITE"/>
                            <CaptureGrid gameState={this.state.gameState} captureColor="BLACK"/>
                        </div>
                        <div className="row">
                            <PieceSelectGrid
                                gameState={this.state.gameState}
                                boardSetupState={this.state.boardSetupState}
                                pieceSelectionCallback={this.handlePlacePieceSelection.bind(this)}
                            />
                            <ColorSetupSelect
                                gameState={this.state.gameState}
                                boardSetupState={this.state.boardSetupState}
                                colorChangeHandler={this.handleColorSetupSelect.bind(this)}
                            />
                        </div>
                    </div>
                </div>
            </Container>
        );
    }
}

Game.propTypes = {
    httpService: PropTypes.func.isRequired,
    gameUuid: PropTypes.string.isRequired,
    error: PropTypes.string
};

export {Game};
