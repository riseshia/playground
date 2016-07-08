from repo import Repo

class Brand:
    _repo = []
    _last_uniq_id = 0

    def __init__(self, name):
        self.name = name
        self.id = None

    # Utility Function
    def _clone(obj):
        new_obj = Brand(obj.name)
        new_obj.id = obj.id
        return new_obj

    # Client Side
    def get(self, key):
        if key == "id":
            return self.id
        elif key == "name":
            return self.name

        return None

    def isValid(self):
        if self.name:
            return True
        else:
            return False

    def save(self):
        if not self.isValid() or Brand.find_by("name", self.name):
            return False

        Repo.create(Brand, self)
        return True

    def update(self):
        brand = Brand.find_by("id", self.id)
        if not self.isValid():
            return False
        elif not (brand and brand.id == self.id):
            return False

        Repo.destroy(Brand, self)
        Repo.create(Brand, self)
        return True

    def delete(self):
        return Repo.destroy(Brand, self)

    def find_by(key, value):
        return Repo.select_by(Brand, key, value)

Repo.register(Brand, ["id", "name"])