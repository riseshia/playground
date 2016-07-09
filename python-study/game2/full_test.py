import unittest
from brand import *
from game import *

class TestGameAndBrand(unittest.TestCase):
    def test_brand_creates_well(self):
        brand = Brand("Brand1")

        self.assertIsNotNone(brand)
        self.assertEqual("Brand1", brand.name)

    def test_brand_is_valid(self):
        brand1 = Brand("Brand2")

        self.assertTrue(brand1.isValid())

    def test_brand_is_not_valid(self):
        brand2 = Brand("")

        self.assertFalse(brand2.isValid())

    def test_brand_will_be_saved(self):
        brand = Brand("Brand3")
        
        self.assertTrue(brand.save())

    def test_brand_will_not_be_saved(self):
        brand = Brand("")

        self.assertFalse(brand.save())

    def test_brand_will_not_be_saved_when_duplicated(self):
        Brand("Brand4").save()

        self.assertFalse(Brand("Brand4").save())

    def test_brand_find_by_name_returns_proper_brand(self):
        Brand("Brand5").save()
        
        self.assertIsNotNone(Brand.find_by("name", "Brand5"))

    def test_brand_find_by_name_returns_none(self):
        self.assertIsNone(Brand.find_by("name", "Brand6"))

    def test_saved_brand_is_not_linked(self):
        brand = Brand("Brand7")
        brand.save()
        brand.name = "Brand7-1"

        self.assertIsNone(Brand.find_by("name", "Brand7-1"))

    def test_found_brand_is_not_linked(self):
        Brand("Brand8").save()
        brand = Brand.find_by("name", "Brand8")
        brand.name = "Brand8-1"

        self.assertIsNone(Brand.find_by("name", "Brand8-1"))

    def test_brand_update_return_true(self):
        Brand("Brand9").save()
        brand = Brand.find_by("name", "Brand9")
        brand.name = "Brand9-1"

        self.assertTrue(brand.update())
        self.assertIsNotNone(Brand.find_by("name", "Brand9-1"))

    def test_brand_update_return_false(self):
        Brand("Brand9").save()
        brand = Brand.find_by("name", "Brand9")
        brand.name = ""

        self.assertFalse(brand.update())
        self.assertIsNotNone(Brand.find_by("name", "Brand9"))

    def test_brand_delete_return_true_when_has_no_game(self):
        Brand("Brand10").save()
        brand = Brand.find_by("name", "Brand10")

        self.assertTrue(brand.delete())
        self.assertIsNone(Brand.find_by("name", "Brand10"))

    def test_brand_delete_return_false_when_invalid_id(self):
        brand = Brand("Brand11")
        brand.id = 1111111

        self.assertFalse(brand.delete())

    def test_brand_delete_return_false_when_unsaved(self):
        brand = Brand("Brand12")

        self.assertFalse(brand.delete())

    def test_game_is_valid_returns_true(self):
        Brand("game1-brand").save()
        brand = Brand.find_by("name", "game1-brand")

        self.assertTrue(Game("game1", brand, 10, "2015-01-01").isValid())

    def test_game_is_valid_returns_false(self):
        Brand("game2-brand").save()
        brand = Brand.find_by("name", "game2-brand")

        self.assertFalse(Game("", brand, 10, "2015-01-01").isValid())
        self.assertFalse(Game("game2-2", brand, 0, "2015-01-01").isValid())
        self.assertFalse(Game("game2-3", brand, 5.5, "2015-01-01").isValid())
        self.assertFalse(Game("game2-4", brand, 11, "2015-01-01").isValid())
        self.assertFalse(Game("game2-5", brand, 10, "").isValid())
        self.assertFalse(Game("game2-5", brand, 10, "2015-00-00").isValid())
        self.assertFalse(Game([], [], 10, []).isValid())

    def test_game_save_returns_true(self):
        Brand("game3-brand").save()
        brand = Brand.find_by("name", "game3-brand")
        new_game = Game("game3", brand, 10, "2015-01-01")

        self.assertTrue(new_game.save())

    def test_game_save_returns_false_with_unsaved_game(self):
        brand = Brand("game4-brand")
        new_game = Game("game4", brand, 10, "2015-01-01")

        self.assertFalse(new_game.save())

    def test_game_save_returns_false_with_duplicated_game(self):
        Brand("game5-brand").save()
        brand = Brand.find_by("name", "game5-brand")
        Game("game5", brand, 10, "2015-01-01").save()
        dup_game = Game("game5", brand, 10, "2015-01-01")

        self.assertFalse(dup_game.save())

    def test_game_find_by_returns_proper_game(self):
        Brand("game6-brand").save()
        brand = Brand.find_by("name", "game6-brand")
        Game("game6", brand, 1, "2000-01-01").save()

        self.assertIsNotNone(Game.find_by("name", "game6"))
        self.assertIsNotNone(Game.find_by("score", 1))
        self.assertIsNotNone(Game.find_by("date", "2000-01-01"))

    def test_game_find_by_returns_none(self):
        self.assertIsNone(Game.find_by("name", "game7"))
        self.assertIsNone(Game.find_by("score", 2))
        self.assertIsNone(Game.find_by("date", "2001-01-01"))

    def test_saved_game_is_not_linked(self):
        Brand("game8-brand").save()
        brand = Brand.find_by("name", "game8-brand")
        game = Game("game8", brand, 10, "2015-01-01")
        game.save()
        game.name = "game8-1"

        self.assertIsNone(Game.find_by("name", "game8-1"))
        self.assertIsNotNone(Game.find_by("name", "game8"))

    def test_found_game_is_not_linked(self):
        Brand("game9-brand").save()
        brand = Brand.find_by("name", "game9-brand")
        Game("game9", brand, 10, "2015-01-01").save()
        game = Game.find_by("name", "game9")
        game.name = "game9-1"

        self.assertIsNone(Game.find_by("name", "game9-1"))
        self.assertIsNotNone(Game.find_by("name", "game9"))

    def test_game_will_be_updated_well(self):
        Brand("game10-brand").save()
        brand = Brand.find_by("name", "game10-brand")
        Game("game10", brand, 10, "2015-01-01").save()
        game = Game.find_by("name", "game10")
        game.name = "game10-1"

        self.assertTrue(game.update())
        self.assertIsNotNone(Game.find_by("name", "game10-1"))

    def test_game_will_not_updated_well_when_unsaved_brand(self):
        Brand("game11-brand").save()
        brand = Brand.find_by("name", "game11-brand")
        Game("game11", brand, 10, "2015-01-01").save()
        game = Game.find_by("name", "game11")
        game.brand_id = Brand("Unsaved").id

        self.assertFalse(game.update())

    def test_game_will_not_updated_well_when_invalid(self):
        Brand("game11-brand").save()
        brand = Brand.find_by("name", "game11-brand")
        Game("game11", brand, 10, "2015-01-01").save()
        game = Game.find_by("name", "game11")
        game.name = ""

        self.assertFalse(game.update())

    def test_game_will_be_deleted(self):
        Brand("game12-brand").save()
        brand = Brand.find_by("name", "game12-brand")
        Game("game12", brand, 10, "2015-01-01").save()
        game = Game.find_by("name", "game12")

        self.assertTrue(game.delete())

    def test_game_will_not_be_deleted_when_unsaved(self):
        Brand("game13-brand").save()
        brand = Brand.find_by("name", "game13-brand")
        game = Game("game13", brand, 10, "2015-01-01")

        self.assertFalse(game.delete())


if __name__ == "__main__":
    unittest.main()
