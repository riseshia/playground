class Game:
    games = []

    def __init__(self, name, brand, score, date):
        self.name = name
        self.brand = brand
        self.score = score
        self.date = date

    def add(game):
        if game.isValid():
            Game.games.append(game)
            return True
        else:
            return False

    def find_by_name(name):
        idx = Game.index(name)
        if idx == -1:
            return None
        else:
            return Game.games[idx]

        return None

    def index(name):
        idx = 0
        for game in Game.games:
            if game.name == name:
                return idx
            else:
                idx += 1

        return -1

    def update(game):
        target_idx = Game.index(game.name)
        if not target_idx == -1:
            del Game.games[target_idx]
            Game.add(game)
            return True
        else:
            return False

    def delete(game):
        target_idx = Game.index(game.name)
        if not target_idx == -1:
            del Game.games[target_idx]
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
        # elif: for Date parsing
        else:
            return True
