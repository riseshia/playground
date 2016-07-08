from datetime import datetime
from brand import Brand
from repo import Repo

class Game:
    def __init__(self, name, brand, score, date):
        self.name = name
        self.score = score
        self.date = date
        self.id = None
        if isinstance(brand, Brand):
            self.brand_id = brand.id
        else:
            self.brand_id = None

    # Utility Function
    def _clone(obj):
        new_obj = Game(obj.name, None, obj.score, obj.date)
        new_obj.id = obj.id
        new_obj.brand_id = obj.brand_id
        return new_obj

    def _isValidBrand(self):
        return self.brand() != None

    # Client Side
    def get(self, key):
        if key == "id":
            return self.id
        elif key == "name":
            return self.name
        elif key == "brand_id":
            return self.brand_id
        elif key == "score":
            return self.score
        elif key == "date":
            return self.date

        return None

    def brand(self):
        return Brand.find_by("id", self.brand_id)

    def isValid(self):
        if not isinstance(self.name, str):
            return False
        elif not self.name:
            return False
        elif not isinstance(self.score, int):
            return False
        elif self.score <= 0 or self.score >= 11:
            return False
        elif not isinstance(self.date, str):
            return False
        elif not self.date:
            return False

        game = Game.find_by("name", self.name)
        if game and game.id != self.id:
            return False
        if not self._isValidBrand():
            return False

        try:
            datetime.strptime(self.date, "%Y-%m-%d")
        except ValueError:
            return False
        else:
            return True

    def save(self):
        if not self.isValid():
            return False

        Repo.create(Game, self)
        return True

    def update(self):
        if not self.isValid():
            return False

        Repo.destroy(Game, self)
        Repo.create(Game, self)
        return True

    def delete(self):
        return Repo.destroy(Game, self)

    def find_by(key, value):
        return Repo.select_by(Game, key, value)


Repo.register(Game, ["id", "name", "brand_id", "date", "score"])