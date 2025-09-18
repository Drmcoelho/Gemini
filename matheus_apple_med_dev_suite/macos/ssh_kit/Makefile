
.PHONY: med-install plot-example obsidian-embed
med-install:
	cd medcli && pipx install . || true

plot-example:
	med plots obs --base https://hapi.fhir.org/baseR4 --patient 123 --code 718-7 --out_png plot.png --title "Lactate"

obsidian-embed:
	./obsidian/embed_plot.sh "$$NOTE" plot.png
