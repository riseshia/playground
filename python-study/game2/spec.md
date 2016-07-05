# 게임 관리 시스템

고객님이 오셔서 아주 깽판을 치고 가셨습니다.

고객이 늘어놓고간 불만에서 사람이 이해할 수 있는 불만 사항은 다음과 같았습니다.

 * 왜 게임 이름은 변경할 수가 없는가.
 * 왜 게임 이름으로만 검색이 되나.
 * 왜 제작사 기준으로 게임 목록을 가져오질 못하나.

왜긴요. 호갱님이 사양을 그 따위로 주셔서 그렇죠.
하지만 작은 고객님을 건드리면 아주 X되는 거에요.
회사에서는 여러가지를 고려해본 결과,
다음과 같이 사양을 변경해야겠다고 결정을 내렸습니다.

 * `Brand` 클래스를 만들기.
 * 여러 컬럼명으로 `Game`을 검색 가능하게 하기.
 * 마음 편하게 이름을 변경할 수 있도록 `Game` 내부에
   각 게임을 구분하기 위한 별도의 식별자를 추가하기.

구체적으로는 다음의 API를 만족하게끔 `Game` 클래스를 개선하고,
`Brand` 클래스를 만들어주세요.
단, 두 클래스는 별도의 파일에서 관리해야 합니다.

### `Brand` 클래스

`Brand` 클래스는 다음의 조건을 만족해야합니다.

 * `id`, `name`이라고 호출하면 각각 제작사의 식별자, 이름을 반환해야 합니다.
 * 식별자는 정상적으로 저장이 된 경우에만 부여되며, 중복되지 않습니다.

### 생성자

`def __init__(self, brand_name)`

생성자는 제작사 이름만을 받습니다.

```python
instance = Brand("Navel")
instance.name # => "Navel"
```

### 제작사 유효성 검증

`def isVaild(self)`

해당 제작사가 유효한지를 검증합니다.
유효하다면 True, 그렇지 않다면 False로 반환해주세요.

 * `name` String(공백 문자열이면 유효하지 않습니다)

```python
brand1 = Brand("Navel")
brand1.isValid() # => True

brand2 = Brand("")
brand1.isValid() # => False
```

### 제작사 검색

`def find_by(key, value)`

`key`에는 제작사의 속성 이름(id, name)을 문자열로 대입하고,
해당 키에 대해서 매칭하기를 원하는 값을 `value`에 넣어주세요.

그러면 첫번째로 조건을 만족하는 제작사를 반환합니다.
만약 만족하는 제작사가 없다면 None을 반환하세요.

```python
Brand("Navel").save()
Brand.find_by("name", "Navel") # => 윗줄에서 저장한 Brand 객체를 반환

Brand.find_by("name", "10cm") # => None
```

### 게임 목록 가져오기

`def games(self)`

해당 제작사에 속해있는 게임 목록을 가져옵니다.
게임 객체로 구성된 리스트로 반환하며, 아무것도 없는 경우 빈 리스트를 반환하세요.

```python
Brand("Navel").save()
navel = Brand.find_by("name", "Navel")
navel.games() # => []

shuffle = Game("Shuffle", navel, 10, "2015-01-01").save()
navel.games() # => [shuffle]
```

### 제작사 업데이트

`def update(self, key, value)`

변경에 성공하면 True, 실패하면 False를 반환합니다.
실패하는 경우는 다음과 같습니다.

 * 저장소 내부에 존재하지 않았을 때(갱신해야할 대상이 존재하지 않을 때)
 * 넘겨받은 제작사 객체가 유효하지 않을 때

```python
Brand("Navel").save()
navel = Brand.find_by("name", "Navel")
navel.name = "New Navel"
navel.update() # => True

navel.name = ""
navel.update() # => False

key = Brand("Key")
key.update() # => False
```

### 제작사 삭제

`def delete(self)`

삭제에 성공하면 True,
실패하면 False를 반환합니다.

다음의 경우에는 제작사를 삭제할 수 없습니다.
 * 해당 제작사가 존재하지 않는 경우
 * 해당 제작사에 속해있는 게임이 존재하는 경우

```python
Brand("Navel").save()
navel = Brand.find_by("name", "Navel")
navel.delete() # => Navel에 속해있는 게임이 없다면 True
navel.delete() # => Navel에 속해있는 게임이 있다면 False

key = Brand("Key")
key.delete() # => False
```

### `Game` 클래스

`Game` 클래스는 다음의 조건을 만족해야합니다.

 * `id`, `name`, `brand`, `score`, `date` 라고 호출하면
   각각 게임의 식별자 이름, 제작사 이름, 평점, 발매일을 반환해야 합니다.
 * 식별자는 **저장**이 되었을 경우에만 부여됩니다.

### `Game` 생성자

`def __init__(self, game_name, saved_brand, score, date)`

```python
Brand("brand_name").save()
brand = Brand.find_by("name", "brand_name")
instance = Game("name", brand, 4, "2015-01-01")
```

### 게임 유효성 검증

`def isValid(self)`

해당 게임이 유효한지를 검증합니다.
이하의 모든 조건을 만족하면 True, 아니면 False로 반환해주세요.

 * 점수가 1~10점 사이일 것
 * 점수가 정수형(int)일 것
 * 모든 속성을 가지고 있을 것
 * 모든 속성이 빈 문자열("")이 아닐 것
 * 발매일 정보가 YYYY-MM-DD 형식일 것


```python
# navel이라는 변수에 저장된 제작사가 있다고 가정
moon = Game("月に寄りそう乙女たちの作法", navel, 10, "2015-01-01")
moon.isValid() # => True

moon = Game("", navel, 10, "2015-01-01")
moon.isValid() # => False
```

### 게임 저장하기

`def save(self)`

성공하면 True, 아니면 False를 반환합니다.
성공한 경우에는 식별자를 부여합니다.
실패하는 경우는 다음과 같습니다.

 * 게임 객체가 유효하지 않은 경우
 * 가지고 있는 제작사의 식별자가 유효하지 않은 경우

```python
# navel이라는 변수에 저장된 제작사가 있다고 가정
moon = Game("月に寄りそう乙女たちの作法", navel, 10, "2015-01-01")
moon.save() # => True

moon = Game("", navel, 10, "2015-01-01")
moon.save() # => False

unknown = Brand("New Brand")
moon.brand = unknown
moon.save() # => False
```

### 제작사 정보 가져오기

`def brand(self)`

해당 게임의 제작사 객체를 가져옵니다.
가져올 수 없는 경우 None을 반환하세요.

```python
# navel이라는 변수에 저장된 제작사가 있다고 가정
Game("Shuffle!!", navel, 10, "2015-01-01").save()
shuffle = Game.find_by("name", "Shuffle!!")
shuffle.brand() # => navel

ever = Game("Ever17", None, 10, "2015-01-01") # Unsaved
ever.brand() # => None
```

### 게임 검색

`def find_by(key, value)`

`key`에는 검색하고 싶은 속성의 이름(name, score, date, brand_id)을
문자열로 넘겨주고, 해당 키에 대해서 매칭하기를 원하는 값을 `value`에 넣어주세요.

첫번째로 조건을 만족하는 게임을 반환합니다.
만약 만족하는 게임이 없다면 None을 반환하세요.

```python
# navel이라는 변수에 저장된 제작사가 있다고 가정
Game("月に寄りそう乙女たちの作法", navel, 10, "2015-01-01").save()
Game.find_by("name", "月に寄りそう乙女たちの作法") # => 윗줄에서 저장한 Game 객체를 반환

Game.find_by("name", "Unknown") # => None
```

### 게임 업데이트

`def update(self)`

변경에 성공하면 True, 실패하면 False를 반환합니다.
실패하는 경우는 다음과 같습니다.

 * 저장소 내부에 존재하지 않았을 때(갱신해야할 대상이 존재하지 않을 때)
 * 넘겨받은 게임 객체가 유효하지 않을 때
 * 가지고 있는 제작사의 식별자가 유효하지 않은 경우

```python
# navel이라는 변수에 저장된 제작사가 있다고 가정
Game("Shuffle!!", navel, 10, "2015-01-01").save()
shuffle = Game.find_by("name", "Shuffle!!")
shuffle.score = 9
shuffle.update() # => True

shuffle.score = 11
shuffle.update() # => False

unknown = Brand("New Brand")
shuffle.brand = unknown
shuffle.save() # => False

ever = Game("Ever17", navel, 10, "2015-01-01") # Unsaved
ever.update() # => False
```

### 게임 삭제

`def delete(self)`

삭제에 성공하면 True,
실패(해당 게임이 존재하지 않으면)하면 False를 반환합니다.

```python
# navel이라는 변수에 저장된 제작사가 있다고 가정
Game("Shuffle!!", navel, 10, "2015-01-01").save()
shuffle = Game.find_by("name", "Shuffle!!")
shuffle.delete() # => True

ever = Game("Ever17", navel, 10, "2015-01-01") # Unsaved
ever.delete() # => False
```

## Test 사용하기

`full_test.py`라는 파일을
게임 클래스 파일(`game.py`)과 제작사 클래스 파일(`brand.py`)와 같은 폴더에 복사합니다.

그리고 실행하세요.
