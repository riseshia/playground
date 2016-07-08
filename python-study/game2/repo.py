class Repo:
    _repos = {}
    _ids = {}
    _attrs = {}

    def _genId(klass):
        Repo._ids[klass] += 1
        return Repo._ids[klass]

    def _getRepo(klass):
        return Repo._repos[klass]

    def _getAttrs(klass):
        return Repo._attrs[klass]

    def register(klass, attrs):
        Repo._ids[klass] = 0
        Repo._repos[klass] = []
        Repo._attrs[klass] = attrs

    def create(klass, obj):
        repo = Repo._getRepo(klass)
        copied = klass._clone(obj)
        if not obj.id:
            copied.id = Repo._genId(klass)
        repo.append(copied)

    def index_by(klass, key, value):
        if not key in Repo._getAttrs(klass): # Whitelist
            return None

        repo = Repo._getRepo(klass)
        idx = 0
        for obj in repo:
            if obj.get(key) == value:
                return idx
            idx += 1

        return None

    def select_by(klass, key, value):
        repo = Repo._getRepo(klass)
        idx = Repo.index_by(klass, key, value)
        if idx == None:
            return None

        return klass._clone(repo[idx])

    def destroy(klass, obj):
        repo = Repo._getRepo(klass)
        idx = Repo.index_by(klass, "id", obj.id)
        if idx == None:
            return False

        del repo[idx]
        return True
