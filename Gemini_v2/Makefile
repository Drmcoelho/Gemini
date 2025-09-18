# Makefile — Gemini Megapack
.PHONY: install doctor uninstall update zip clean

install:
	@./install.sh

doctor:
	@./doctor.sh

uninstall:
	@./uninstall.sh

update:
	@echo "[INFO] (placeholder) Atualizações locais: nada a fazer."

zip:
	@cd .. && zip -r gemini_megapack.zip gemini_megapack

clean:
	@find . -name "__pycache__" -type d -exec rm -rf {} +
	@find . -name ".DS_Store" -type f -delete
