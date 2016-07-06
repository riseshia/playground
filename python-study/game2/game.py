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

    def _genId():
        Game._last_uniq_id += 1
        return Game._last_uniq_id

    def _clone(obj):
        new_obj = Game(obj.name, None, obj.score, obj.date)
        new_obj.id = obj.id
        new_obj.brand_id = obj.brand_id
        return new_obj

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
        elif not Brand.find_by("id", self.brand_id):
            return False
        elif not Game.find_by("name", self.name):
            obj = Game._clone(self)
            obj.id = Game._genId()
            Game._repo.append(obj)
            return True
        else:
            return False

    def update(self):
        if not self.isValid():
            return False
        elif not self.id:
            return False
        elif not Brand.find_by("id", self.brand_id):
            return False

        game = Game.find_by("id", self.id)
        if game and game.id == self.id:
            idx = 0
            for inner_game in Game._repo:
                if inner_game.id == self.id:
                    del Game._repo[idx]
                idx += 1

            Game._repo.append(Game._clone(self))
            return True

        return False

    def delete(self):
        if not self.id:
            return False

        idx = 0
        for inner_game in Game._repo:
            if inner_game.id == self.id:
                del Game._repo[idx]
            return True
            idx += 1

        return False

    def find_by(key, value):
        for brand in Game._repo:
            if key == "id" and brand.id == value:
                return Game._clone(brand)
            elif key == "name" and brand.name == value:
                return Game._clone(brand)
            elif key == "score" and brand.score == value:
                return Game._clone(brand)
            elif key == "date" and brand.date == value:
                return Game._clone(brand)

        return None
