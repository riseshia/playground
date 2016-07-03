from datetime import datetime

class Game:
    _games = []

    def __init__(self, name, brand, score, date):
        self.name = name
        self.brand = brand
        self.score = score
        self.date = date

    def add(game):
        if game.isValid() and Game._index(game.name) == -1:
            Game._games.append(game)
            return True
        else:
            return False

    def find_by_name(name):
        idx = Game._index(name)
        if idx != -1:
            return Game._games[idx]._clone()

    def update(game):
        target_idx = Game._index(game.name)
        if not target_idx == -1:
            del Game._games[target_idx]
            Game._games.append(game)
            return True
        else:
            return False

    def delete(game):
        target_idx = Game._index(game.name)
        if not target_idx == -1:
            del Game._games[target_idx]
            return True
        else:
            return False

    def isValid(self):
        if not isinstance(self.name, str):
            return False
        elif not self.name:
            return False
        elif not isinstance(self.brand, str):
            return False
        elif not self.brand:
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

    def _clone(self):
        return Game(self.name, self.brand, self.score, self.date)

    def _index(name):
        idx = 0
        for game in Game._games:
            if game.name == name:
                return idx
            else:
                idx += 1

        return -1
