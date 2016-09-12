#!/usr/local/bin/python
from com.johnmalcolmnorwood.stupidchess.models.move import Move, MoveType
from com.johnmalcolmnorwood.stupidchess.models.game import Game
from com.johnmalcolmnorwood.stupidchess.utils import get_piece_for_move_db_object


class MoveApplicationService(object):
    def __init__(self, setup_squares_for_color, possible_move_service):
        self.__setup_squares_for_color = setup_squares_for_color
        self.__possible_move_service = possible_move_service

    def apply_move(self, move, game_uuid):
        """
        Applies a move to the game with the input uuid. Will first retrieve a query that will ensure the game, then will
        ensure that the move is legal. Then it writes a move object to the move collection, and finally applies the
        update to the game state. The order of these operations along with indexes on the move and game collections
        guarantees the thread safety of this update.

        :param move: The move being applied
        :param game_uuid: The uuid of the game that the move is being applied to
        """
        # Retrieve the current game, we will need it to check the legality of the move being performed, and to get the
        # index of the last move
        game = MoveApplicationService.__get_game_for_move(move, game_uuid)

        # Get the full move object, with captures and all, if this method returns None, the move wasn't legal and we
        # raise an exception
        full_move = self.__get_full_move(move, game)
        if full_move is None:
            raise Exception()

        # If we've made it here, the move was legal, and we've written the move to the collection, essentially locking
        # the game state for us to make an update on it. Apply those updates now
        self.__apply_updates_for_move(full_move, game)

    @staticmethod
    def __get_game_for_move(move, game_uuid):
        # In the case of a PLACE move, we do the verification of the legality of the move in the query to retrieve the
        # game, if we can find a game with the matching game_uuid, and a square to be placed and piece that match with
        # the input place move, then the move is legal
        if move.type == MoveType.PLACE:
            return MoveApplicationService.__get_game_for_place_move(move, game_uuid)

        # For a MOVE move, we need the whole game state to determine if the move is legal
        elif move.type == MoveType.MOVE:
            exclude_fields = [
                'createTimestamp', 'lastUpdateTimestamp', '_id',
            ]

            return Game.objects.exclude(*exclude_fields).get(_id=game_uuid)

    @staticmethod
    def __get_game_for_place_move(move, game_uuid):
        piece_to_be_placed_match = {
            'color': move.piece.color,
            'type': move.piece.type,
            'index': move.piece.index,
        }

        game_query = {
            '_id': game_uuid,
            'squaresToBePlaced': move.destinationSquare,
            'possiblePiecesToBePlaced': {'$elemMatch': piece_to_be_placed_match},
        }

        return Game.objects.only('lastMove', 'squaresToBePlaced', 'possiblePiecesToBePlaced').get(__raw__=game_query)

    def __apply_updates_for_move(self, full_move, game):
        if full_move.type == MoveType.PLACE:
            self.__apply_updates_for_place_move(full_move, game)
        elif full_move.type == MoveType.MOVE:
            pass

    def __apply_updates_for_place_move(self, full_move, game):
        additional_necessary_placements = self.__get_additional_necessary_placements(full_move, game)
        moves = [full_move, *additional_necessary_placements]

        # Add the new move objects
        for idx, move in enumerate(moves, start=game.lastMove + 1):
            move.index = idx

        Move.objects.insert(MoveApplicationService.__get_move_for_insert(move) for move in moves)

        square_removals = [move.destinationSquare for move in moves]
        piece_removals = self.__get_piece_removal_for_moves(moves, full_move.piece.color)
        piece_additions = [MoveApplicationService.__get_piece_addition_for_move(move) for move in moves]

        updates = {
            '$pull': {
                'squaresToBePlaced': {'$in': square_removals},
                'possiblePiecesToBePlaced': piece_removals,
            },
            '$push': {
                'pieces': {'$each': piece_additions},
            },
            '$inc': {'lastMove': len(moves)},
            '$currentDate': {'lastUpdateTimestamp': True},
        }

        Game.objects(_id=game.get_id()).update(__raw__=updates)

    @staticmethod
    def __get_piece_removal_for_moves(moves, color):
        return {
            '$and': [
                {'color': color},
                {'$or': [
                    {'type': move.piece.type, 'index': move.piece.index} for move in moves
                ]},
            ],
        }

    @staticmethod
    def __get_piece_addition_for_move(move):
        return {
            'color': move.piece.color,
            'type': move.piece.type,
            'square': move.destinationSquare,
        }

    def __get_additional_necessary_placements(self, last_move, game):
        """
        Applies any additional place moves if they are inevitable, for instance, if there are only pieces of a single type
        remaining, or if the user has only one piece left to place, the user has no choice where things are going to be placed
        so it may as well happen automatically

        :param game: The game to which moves are being applied
        :param last_move: The move that was just performed
        """
        piece_color = last_move.piece.color

        def piece_filter(piece):
            return piece.color == piece_color and piece.index != last_move.piece.index

        def square_filter(square):
            return square != last_move.destinationSquare and self.__is_square_in_setup_zone_for_color(
                piece_color,
                square,
            )

        players_other_pieces = list(filter(piece_filter, game.possiblePiecesToBePlaced))
        players_other_squares = list(filter(square_filter, game.squaresToBePlaced))

        if len(players_other_pieces) == 0:
            return []

        # Otherwise, see if the only remaining pieces for that color are of the same type, then they can all be
        # placed in remaining spots for the user
        piece_type = players_other_pieces[0].type
        for piece in players_other_pieces:
            if piece.type != piece_type:
                return []

        return MoveApplicationService.__build_place_moves_for_pieces(players_other_pieces, players_other_squares, game)

    @staticmethod
    def __build_place_moves_for_pieces(placers_other_pieces, players_other_squares, game):
        def build_move(idx, piece):
            return Move(
                type=MoveType.PLACE,
                piece=piece,
                destinationSquare=players_other_squares[idx],
                gameUuid=game.get_id(),
            )

        return [
            build_move(idx, piece) for idx, piece in enumerate(placers_other_pieces)
        ]

    @staticmethod
    def __get_move_for_insert(move):
        move_piece = get_piece_for_move_db_object(move.piece)

        return Move(
            type=move.type,
            piece=move_piece,
            index=move.index,
            destinationSquare=move.destinationSquare,
            gameUuid=move.gameUuid,
        )

    def __is_square_in_setup_zone_for_color(self, color, square):
        return square in self.__setup_squares_for_color[color]

    @staticmethod
    def __get_full_move(move, game):
        move.gameUuid = game.get_id()

        if move.type == MoveType.PLACE:
            return move
        elif move.type == MoveType.MOVE:
            return move
