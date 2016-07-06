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

    def _destroy(obj):
        idx = 0
        for brand in Brand._repo:
            if brand.id == obj.id:
                del Brand._repo[idx]
                return True
            idx += 1

        return False

    # Client Side
    def isValid(self):
        if self.name:
            return True
        else:
            return False

    def save(self):
        if not self.isValid() or Brand.find_by("name", self.name):
            return False

        obj = Brand(self.name)
        obj.id = Brand._genId()
        Brand._repo.append(obj)
        return True

    def update(self):
        if not (self.isValid() and self.id):
            return False

        brand = Brand.find_by("id", self.id)
        if not (brand and brand.id == self.id):
            return False

        Brand._destroy(self)
        Brand._create(self)
        return True

    def delete(self):
        if not self.id:
            return False

        return Brand._destroy(self)

    def find_by(key, value):
        for brand in Brand._repo:
            if key == "id" and brand.id == value:
                return Brand._clone(brand)
            elif key == "name" and brand.name == value:
                return Brand._clone(brand)

        return None
