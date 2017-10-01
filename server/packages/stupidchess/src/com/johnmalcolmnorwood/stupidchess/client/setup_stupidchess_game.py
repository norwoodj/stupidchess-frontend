#!/usr/local/bin/python
import requests
import click

from jconfigure import configure
from com.johnmalcolmnorwood.stupidchess import LOGGER
from com.johnmalcolmnorwood.stupidchess.models.piece import PieceType, Color
from com.johnmalcolmnorwood.stupidchess.models.move import MoveType


def make_move(piece_type, color, square):
    return {
        "type": MoveType.PLACE,
        "destinationSquare": square,
        "piece": {
            "type": piece_type,
            "color": color,
        },
    }

STUPID_CHESS_URL = "http://localhost/api/{endpoint}"
BLACK_SETUP_MOVES = [
    *[make_move(PieceType.PAWN, Color.BLACK, i) for i in range(20, 24)],
    make_move(PieceType.PONY, Color.BLACK, 12),
    make_move(PieceType.CHECKER, Color.BLACK, 11),
    make_move(PieceType.CASTLE, Color.BLACK, 10),
    make_move(PieceType.CASTLE, Color.BLACK, 13),
    make_move(PieceType.BISHOP, Color.BLACK, 0),
    make_move(PieceType.BISHOP, Color.BLACK, 3),
    make_move(PieceType.QUEEN, Color.BLACK, 1),
]

WHITE_SETUP_MOVES = [
    *[make_move(PieceType.PAWN, Color.WHITE, i) for i in range(94, 98)],
    make_move(PieceType.PONY, Color.WHITE, 106),
    make_move(PieceType.CHECKER, Color.WHITE, 105),
    make_move(PieceType.CASTLE, Color.WHITE, 104),
    make_move(PieceType.CASTLE, Color.WHITE, 107),
    make_move(PieceType.BISHOP, Color.WHITE, 114),
    make_move(PieceType.BISHOP, Color.WHITE, 117),
    make_move(PieceType.QUEEN, Color.WHITE, 115),
]


def add_moves(stupidchess_url, game_uuid, moves, username, password):
    for idx, move in enumerate(moves):
        move["piece"]["index"] = idx

        response = requests.post(
            url=f"{stupidchess_url}/api/game/{game_uuid}/move/",
            json=move,
            auth=(username, password),
        )

        response.raise_for_status()
        move_texts = (
            f"{m['id']} ({m['type']} {m['piece']['color']} {m['piece']['type']} at {m['destinationSquare']})"
            for m in response.json()["moves"]
        )

        LOGGER.info(f"Added Move(s) {', '.join(move_texts)}")


@click.command()
@click.option("--stupidchess", "-s", default="http://localhost")
@click.option("--black_username", "-b", default="veintitres")
@click.option("--black_password", "-c", default="password")
@click.option("--white_username", "-w")
@click.option("--white_password", "-x")
@click.argument("game_uuid")
def main(stupidchess, black_username, black_password, white_username, white_password, game_uuid):
    configure()

    if white_username is None:
        white_username = black_username
    if white_password is None:
        white_password = black_password

    LOGGER.info(f"Setting up game for board {game_uuid} on stupidchess server {stupidchess}")
    LOGGER.info("Adding Black moves...")
    add_moves(stupidchess, game_uuid, BLACK_SETUP_MOVES, black_username, black_password)

    LOGGER.info("Adding White moves...")
    add_moves(stupidchess, game_uuid, WHITE_SETUP_MOVES, white_username, white_password)


if __name__ == "__main__":
    main()
