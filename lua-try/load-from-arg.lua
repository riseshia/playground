-- 실행 시 첫 번째 인자를 경로로 받음
local file = arg[1]

if not file then
    print("파일 경로를 입력하세요.")
    os.exit(1)
end

-- 파일을 로드하고 실행
local ast_data = assert(loadfile(file))()

-- 이제 astver와 astname 변수를 사용할 수 있습니다.
print("astver:", astver)  -- 예: 2.0
print("astname:", astname) -- 예: "ast"
