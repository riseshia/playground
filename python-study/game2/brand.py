class Brand:
    _brands = []
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
            Brand._brands.append(obj)
            return True
        else:
            return False

    def update(self):
        if self.isValid() and self.id:
            brand = Brand.find_by("id", self.id)
            if brand and brand.id == self.id:
                for inner_brand in Brand._brands:
                    if inner_brand.id == self.id:
                        del inner_brand

                Brand._brands.append(Brand._clone(self))
                return True

        return False

    def delete(self):
        if not self.id:
            return False

        for inner_brand in Brand._brands:
            if inner_brand.id == self.id:
                del inner_brand
                print(Brand._brands)
            return True

        return False

    def find_by(key, value):
        for brand in Brand._brands:
            if key == "id" and brand.id == value:
                return Brand._clone(brand)
            elif key == "name" and brand.name == value:
                return Brand._clone(brand)

        return None

