#!/bin/bash
# ============================================================================
#  VIDEO STUDIO MOBILE - SETUP SCRIPT CHO MOI TRUONG CLAUDE CODE CLOUD
#  Duoc tai tu https://newstarland-media.github.io/chon-video/setup.sh
#  O "Setup script" cua moi truong chi can 2 dong (xem docs/HUONG-DAN-CAI-DAT.md, Phan 3).
#  Chay 1 lan, Anthropic luu lai ~7 ngay (neu chay xong trong ~5 phut).
#  Khong phu thuoc repo: chi cai cong cu + tai font + tai model nho.
# ============================================================================
set -uo pipefail
export DEBIAN_FRONTEND=noninteractive
START=$(date +%s)
log(){ echo "[setup $(( $(date +%s) - START ))s] $*"; }
MODELS=/opt/models; mkdir -p "$MODELS/hf" "$MODELS/papercut" /opt/nodedeps

# ---------- 1. Goi he thong ----------
log "apt"
apt-get update -qq || true
apt-get install -y -qq --no-install-recommends \
  ffmpeg rclone imagemagick mediainfo sox fontconfig unzip python-is-python3 \
  fonts-dejavu-core fonts-noto-core >/dev/null || log "CANH BAO: apt chinh loi"
apt-get install -y -qq --no-install-recommends fonts-montserrat >/dev/null 2>&1 || true

# ---------- 2. Thu vien Python (tang 1) ----------
log "pip"
PIP="python3 -m pip install -q --disable-pip-version-check --break-system-packages"
$PIP --upgrade pip >/dev/null 2>&1 || true
$PIP \
  faster-whisper edge-tts yt-dlp gdown "scenedetect[opencv-headless]" opencv-python-headless \
  librosa soundfile pyloudnorm pydub numpy pillow \
  pymupdf pypdf python-docx openpyxl trafilatura beautifulsoup4 requests \
  playwright onnxruntime sherpa-onnx auto-editor \
  || log "CANH BAO: pip co goi loi"

# Chromium cho playwright (Python). Node dung Chrome co san qua CHROME_PATH.
log "playwright chromium"
python3 -m playwright install chromium >/dev/null 2>&1 || log "CANH BAO: khong tai duoc chromium playwright"

# ---------- 3. Node: HyperFrames + playwright dung chung ----------
log "npm"
npm install -g --silent --no-audit --no-fund hyperframes >/dev/null 2>&1 || log "CANH BAO: khong cai duoc hyperframes"
(cd /opt/nodedeps && npm init -y >/dev/null 2>&1 && npm install --silent --no-audit --no-fund playwright >/dev/null 2>&1) \
  || log "CANH BAO: khong cai duoc playwright node"

# ---------- 4. Font tieng Viet ----------
log "fonts"
FD=/usr/share/fonts/truetype   # de file ngay cap nay: mot so script chi tim o day
for w in Thin Light Regular Medium SemiBold Bold ExtraBold Black BlackItalic BoldItalic Italic; do
  curl -fsSL -o "$FD/BeVietnamPro-$w.ttf" \
    "https://github.com/google/fonts/raw/main/ofl/bevietnampro/BeVietnamPro-$w.ttf" || true
done
for f in "Montserrat[wght].ttf" "Montserrat-Italic[wght].ttf" "PlayfairDisplay[wght].ttf" "Inter[opsz,wght].ttf"; do
  dir=$(echo "$f" | sed -E 's/(-Italic)?\[.*//' | tr 'A-Z' 'a-z')
  curl -fsSL -o "$FD/$(echo "$f" | tr -d '[]')" "https://github.com/google/fonts/raw/main/ofl/$dir/$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$f")" || true
done
fc-cache -f >/dev/null 2>&1 || true

# ---------- 5. Model nho (duoc luu cung snapshot) ----------
log "models"
curl -fsSL -o "$MODELS/papercut/rvm_mobilenetv3_fp32.onnx" \
  https://github.com/PeterL1n/RobustVideoMatting/releases/download/v1.0.0/rvm_mobilenetv3_fp32.onnx || true
HF_HOME="$MODELS/hf" timeout 240 python3 - <<'PY' || echo "CANH BAO: tai model whisper chua xong (se tai khi dung)"
from faster_whisper import WhisperModel
for m in ("small", "large-v3-turbo"):
    WhisperModel(m, device="cpu", compute_type="int8"); print("whisper", m, "ok")
PY
chmod -R a+rwX "$MODELS" /opt/nodedeps 2>/dev/null || true

# ---------- 6. Bao cao ----------
for t in ffmpeg ffprobe rclone yt-dlp edge-tts auto-editor hyperframes node python3; do
  command -v "$t" >/dev/null && echo "OK  $t" || echo "THIEU $t"
done
log "XONG"
exit 0
