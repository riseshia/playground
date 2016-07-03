import unittest
from game import *


class TestGame(unittest.TestCase):
    def test_isValid_returns_true(self):
        self.assertTrue(Game("game1", "brand", 10, "2015-01-01"))

    def test_isValid_returns_false(self):
        self.assertFalse(Game("", "brand", 10, "2015-01-01").isValid())
        self.assertFalse(Game("game2-1", "", 10, "2015-01-01").isValid())
        self.assertFalse(Game("game2-2", "brand", 0, "2015-01-01").isValid())
        self.assertFalse(Game("game2-3", "brand", 5.5, "2015-01-01").isValid())
        self.assertFalse(Game("game2-4", "brand", 11, "2015-01-01").isValid())
        self.assertFalse(Game("game2-5", "brand", 10, "").isValid())
        self.assertFalse(Game("game2-5", "brand", 10, "2015-00-00").isValid())
        self.assertFalse(Game([], [], 10, []).isValid())

    def test_add_returns_true(self):
        new_game = Game("game3", "brand", 10, "2015-01-01")
        self.assertTrue(Game.add(new_game))

    def test_add_returns_false_with_invalid_game(self):
        new_game = Game("game4", "", 10, "2015-01-01")
        self.assertFalse(Game.add(new_game))

    def test_add_returns_false_with_duplicated_game(self):
        game = Game("game4", "", 10, "2015-01-01")
        Game.add(game)
        dup_game = Game("game4", "", 10, "2015-01-01")
        self.assertFalse(Game.add(dup_game))

    def test_find_by_name_returns_game(self):
        game = Game("game5", "brand", 10, "2015-01-01")
        Game.add(game)

        found_game = Game.find_by_name(game.name)
        self.assertTrue(found_game != None)
        self.assertEqual(game.name, found_game.name)
        self.assertEqual(game.brand, found_game.brand)
        self.assertEqual(game.score, found_game.score)
        self.assertEqual(game.date, found_game.date)

    def test_find_by_name_returns_none(self):
        self.assertTrue(Game.find_by_name("game6") is None)

    def test_update_returns_true(self):
        game = Game("game7", "brand", 10, "2015-01-01")
        Game.add(game)
        fixed_game = Game("game7", "brand", 4, "2015-01-01")

        self.assertTrue(Game.update(fixed_game))
        self.assertEqual(4, Game.find_by_name(fixed_game.name).score)

    def test_update_returns_false_until_updated(self):
        Game.add(Game("game7", "brand", 10, "2015-01-01"))
        game = Game.find_by_name("game7")
        game.name = "game7-1"

        self.assertTrue(Game.find_by_name(game.name) == None)

    def test_update_retuns_false(self):
        new_game = Game("game8", "brand", 10, "2015-01-01")

        self.assertFalse(Game.update(new_game))

    def test_delete_returns_true(self):
        new_game = Game("game9", "brand", 10, "2015-01-01")
        Game.add(new_game)

        self.assertTrue(Game.delete(new_game))

    def test_delete_returns_false(self):
        new_game = Game("game10", "brand", 10, "2015-01-01")

        self.assertFalse(Game.delete(new_game))


if __name__ == "__main__":
    unittest.main()
