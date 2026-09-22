#!/usr/bin/env bash
# OSTEP homework 실습 환경 점검 (학생 Codespace용)  v2
# 결과는 화면과 hw/setup/check-result.txt 에 함께 기록됩니다.
ROOT=${ROOT:-/workspaces/ostep-codespace-lab}
HW="$ROOT/ext/ostep-homework"; CODE="$ROOT/ext/ostep-code"
PASS=0; FAIL=0; LOG=/tmp/ostep-check.log; : > "$LOG"
ITEMS=()
now_ms(){ echo $(( $(date +%s%N) / 1000000 )); }
record(){ ITEMS+=("$(printf '%s\t%s\t%s' "$1" "$2" "$3")"); }
ok(){ printf '  [PASS] %s\n' "$1"; PASS=$((PASS+1)); record PASS "$1" "$2"; }
ng(){ printf '  [FAIL] %s  <- %s\n' "$1" "$3"; FAIL=$((FAIL+1)); record FAIL "$1" "$2"; }
run(){ d=$1; shift; t0=$(now_ms); out=$("$@" 2>&1); rc=$?; dt=$(( $(now_ms) - t0 ))
  echo "== $d (rc=$rc)" >> "$LOG"; echo "$out" >> "$LOG"
  if [ $rc -eq 0 ]; then ok "$d" "$dt"; else ng "$d" "$dt" "$(echo "$out" | grep -v '^\s*$' | tail -1)"; fi; }

STARTED=$(date -u +%Y-%m-%dT%H:%M:%SZ); T_START=$(now_ms)
NONCE=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || date +%s%N)

echo "[1] 기본 환경"
run "Ubuntu 24.04"            grep -qx 'VERSION_CODENAME=noble' /etc/os-release
run "python 명령 = Python 3"  sh -c 'python --version 2>&1 | grep -q "^Python 3"'
run "tkinter"                 python3 -c 'import tkinter'
for t in gcc make gdb strace ltrace valgrind vmstat; do run "$t 설치" sh -c "command -v $t"; done
run "gdb로 프로그램 실행"      sh -c 'gdb -batch -ex run --args /bin/true 2>&1 | grep -q "exited normally"'
run "strace 권한"             strace -o /dev/null /bin/true

echo "[2] 저장소와 homework 코드"
run "저장소 폴더"             test -d "$ROOT/.git"
run "origin이 학생 fork"      sh -c "git -C '$ROOT' remote get-url origin | grep -vq 'github.com/pythonandbenjamin/'"
run "ext/ostep-homework"      test -d "$HW/.git"
run "ext/ostep-code"          test -d "$CODE/.git"
run "homework 버전 afb36ca"   sh -c "git -C '$HW' rev-parse --short=7 HEAD | grep -qx afb36ca"
run "ext/는 git 추적 제외"    git -C "$ROOT" check-ignore -q ext

# 원본 ext 폴더를 건드리지 않도록 임시 복사본에서 점검
T=/tmp/ostep-check; rm -rf "$T"; mkdir -p "$T"
[ -d "$HW" ] && cp -r "$HW" "$T/hw"; [ -d "$CODE" ] && cp -r "$CODE" "$T/code"

echo "[3] Python 시뮬레이터 (README 예시 옵션 + -c)"
if [ -d "$T/hw" ]; then
  cd "$T/hw"
  for f in */*.py; do
    dir=${f%/*}; py=${f#*/}
    case "$f" in
      file-raid/raid-graphics.py) echo "  [SKIP] $f  (Python 2 전용 그래픽 버전)"; continue;;
      file-ffs/ffs.py) args="-f in.example1 -c";;
      cpu-intro/process-run.py|file-devices/process-run.py) args="-l 5:100 -c";;
      file-implementation/vsfs.py) args="-n 6 -s 16 -c";;
      threads-intro/x86.py) args="-p simple-race.s -t 1 -c";;
      threads-locks/x86.py) args="-p flag.s -c";;
      cpu-api/generator.py) args="-s 1 -S 1 -c";;
      *) args="-c";;
    esac
    t0=$(now_ms); out=$(cd "$dir" && timeout 30 "./$py" $args </dev/null 2>&1); rc=$?; dt=$(( $(now_ms) - t0 ))
    echo "== $f (rc=$rc)" >> "$LOG"; echo "$out" | tail -20 >> "$LOG"
    if [ $rc -ne 0 ] || echo "$out" | grep -qE 'Traceback|No such file'; then ng "$f" "$dt" "$(echo "$out" | tail -1)"; else ok "$f" "$dt"; fi
  done
  cd "$ROOT"
fi

echo "[4] C 과제 빌드 (make)"
for d in threads-api threads-cv threads-bugs vm-beyondphys; do
  [ -d "$T/hw/$d" ] && run "homework/$d" make -C "$T/hw/$d" -s
done
for d in intro cpu-api vm-intro threads-intro threads-api threads-locks threads-cv threads-sema threads-bugs file-intro dist-intro cpu-sched-lottery; do
  [ -f "$T/code/$d/Makefile" ] && run "code/$d" make -C "$T/code/$d" -s
done

echo "[5] 실행 확인"
[ -x "$T/hw/threads-api/main-race" ] && run "helgrind가 경쟁 조건 탐지" sh -c "valgrind --tool=helgrind '$T/hw/threads-api/main-race' 2>&1 | grep -q 'Possible data race'"
[ -x "$T/hw/vm-beyondphys/mem" ] && run "mem 실행 (3초)" sh -c "timeout 3 '$T/hw/vm-beyondphys/mem' 1 >/dev/null 2>&1; [ \$? -eq 124 ]"
run "vmstat 실행"             vmstat 1 2
[ -x "$T/code/intro/cpu" ] && run "code/intro/cpu 실행" sh -c "timeout 3 '$T/code/intro/cpu' A >/dev/null 2>&1; [ \$? -eq 124 ]"

# ---------- 결과 파일 (제출용) ----------
FINISHED=$(date -u +%Y-%m-%dT%H:%M:%SZ); DURATION=$(( $(now_ms) - T_START ))
SELF="${BASH_SOURCE[0]}"
RECEIPT="$ROOT/hw/setup/check-result.txt"; mkdir -p "$(dirname "$RECEIPT")"
BODY=$(
  echo "# OSTEP OS Lab check result"
  echo "format: 2"
  echo "github_user: ${GITHUB_USER:-}"
  echo "codespaces: ${CODESPACES:-}"
  echo "codespace_name: ${CODESPACE_NAME:-}"
  echo "github_repository: ${GITHUB_REPOSITORY:-}"
  echo "origin: $(git -C "$ROOT" remote get-url origin 2>/dev/null)"
  echo "repo_head: $(git -C "$ROOT" rev-parse HEAD 2>/dev/null)"
  echo "homework_commit: $(git -C "$HW" rev-parse --short=7 HEAD 2>/dev/null)"
  echo "check_sh_sha256: $(sha256sum "$SELF" | cut -d' ' -f1)"
  echo "kernel: $(uname -r)"
  echo "os: $(. /etc/os-release; echo "$PRETTY_NAME")"
  echo "cpus: $(nproc)"
  echo "boot_id: $(cat /proc/sys/kernel/random/boot_id 2>/dev/null)"
  echo "run_id: $NONCE"
  echo "started_utc: $STARTED"
  echo "finished_utc: $FINISHED"
  echo "duration_ms: $DURATION"
  echo "result: PASS $PASS / FAIL $FAIL"
  echo "items:"
  for it in "${ITEMS[@]}"; do echo "  $it"; done
)
{ echo "$BODY"; echo "result_sha256: $(printf '%s\n' "$BODY" | sha256sum | cut -d' ' -f1)"; } > "$RECEIPT"

echo
echo "결과 파일: hw/setup/check-result.txt  (commit, push해서 제출)"
echo "결과: PASS $PASS / FAIL $FAIL   (상세 로그: $LOG)"
[ $FAIL -eq 0 ] && echo "OSTEP homework를 수행할 준비가 되었습니다." || echo "FAIL 항목과 로그를 확인하세요."
