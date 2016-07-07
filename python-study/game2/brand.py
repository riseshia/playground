class Brand:
    _repo = []
    _last_uniq_id = 0

    def __init__(self, name):
        self.name = name
        self.id = None

    # Utility Function
    def _genId():
        Brand._last_uniq_id += 1
        return Brand._last_uniq_id

    def _clone(obj):
        new_obj = Brand(obj.name)
        new_obj.id = obj.id
        return new_obj

    # Server Side
    def _create(obj):
        copied = Brand._clone(obj)
        if not obj.id:
            copied.id = Brand._genId()
        Brand._repo.append(copied)

    def _index_by(key, value):
        idx = 0
        for brand in Brand._repo:
            if key == "id" and brand.id == value:
                return idx
            elif key == "name" and brand.name == value:
                return idx
            idx += 1

    def _select_by(key, value):
        idx = Brand._index_by(key, value)
        if idx != None:
            return Brand._clone(Brand._repo[idx])
        else:
            return None

    def _destroy(obj):
        idx = Brand._index_by("id", obj.id)
        if idx == None:
            return False

        del Brand._repo[idx]
        return True

    # Client Side
    def isValid(self):
        if self.name:
            return True
        else:
            return False

    def save(self):
        if not self.isValid() or Brand.find_by("name", self.name):
            return False

        Brand._create(self)
        return True

    def update(self):
        brand = Brand.find_by("id", self.id)
        if not self.isValid():
            return False
        elif not (brand and brand.id == self.id):
            return False

        Brand._destroy(self)
        Brand._create(self)
        return True

    def delete(self):
        return Brand._destroy(self)

    def find_by(key, value):
        return Brand._select_by(key, value)
