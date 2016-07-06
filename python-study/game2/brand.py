class Brand:
    _repo = []
    _last_uniq_id = 0

    def __init__(self, name):
        self.name = name
        self.id = None

    def _genId():
        Brand._last_uniq_id += 1
        return Brand._last_uniq_id

    def _clone(obj):
        new_obj = Brand(obj.name)
        new_obj.id = obj.id
        return new_obj

    def isValid(self):
        if not self.name:
            return False
        else:
            return True

    def save(self):
        if self.isValid() and not Brand.find_by("name", self.name):
            obj = Brand(self.name)
            obj.id = Brand._genId()
            Brand._repo.append(obj)
            return True
        else:
            return False

    def update(self):
        if self.isValid() and self.id:
            brand = Brand.find_by("id", self.id)
            if brand and brand.id == self.id:
                idx = 0
                for inner_brand in Brand._repo:
                    if inner_brand.id == self.id:
                        del Brand._repo[idx]

                Brand._repo.append(Brand._clone(self))
                return True

        return False

    def delete(self):
        if not self.id:
            return False

        idx = 0
        for inner_brand in Brand._repo:
            if inner_brand.id == self.id:
                del Brand._repo[idx]
            return True
            idx += 1

        return False

    def find_by(key, value):
        for brand in Brand._repo:
            if key == "id" and brand.id == value:
                return Brand._clone(brand)
            elif key == "name" and brand.name == value:
                return Brand._clone(brand)

        return None
