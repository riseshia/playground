from datetime import datetime
from brand import Brand

class Game:
    _repo = []
    _last_uniq_id = 0

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
    def _genId():
        Game._last_uniq_id += 1
        return Game._last_uniq_id

    def _clone(obj):
        new_obj = Game(obj.name, None, obj.score, obj.date)
        new_obj.id = obj.id
        new_obj.brand_id = obj.brand_id
        return new_obj

    # Server Side
    def _create(obj):
        copied = Game._clone(obj)
        if not obj.id:
            copied.id = Game._genId()
        Game._repo.append(copied)

    def _index_by(key, value):
        idx = 0
        for game in Game._repo:
            if key == "id" and game.id == value:
                return idx
            elif key == "name" and game.name == value:
                return idx
            elif key == "score" and game.score == value:
                return idx
            elif key == "date" and game.date == value:
                return idx
            idx += 1

    def _select_by(key, value):
        idx = Game._index_by(key, value)
        if idx != None:
            return Game._clone(Game._repo[idx])
        else:
            return None


    def _destroy(obj):
        idx = Game._index_by("id", obj.id)
        if idx == None:
            return False

        del Game._repo[idx]
        return True

    # Client Side
    def _isValidBrand(self):
        return self.brand() != None

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

        try:
            datetime.strptime(self.date, "%Y-%m-%d")
        except ValueError:
            return False
        else:
            return True

    def save(self):
        if not self.isValid():
            return False
        elif not self._isValidBrand():
            return False
        elif Game.find_by("name", self.name):
            return False

        Game._create(self)
        return True

    def update(self):
        game = Game.find_by("id", self.id)
        if not self.isValid():
            return False
        elif not self._isValidBrand():
            return False
        elif not(game and game.id == self.id):
            return False

        Game._destroy(self)
        Game._create(self)
        return True

    def delete(self):
        return Game._destroy(self)

    def find_by(key, value):
        return Game._select_by(key, value)
