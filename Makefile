NAME=KsKit
DISTFILES=$(NAME).pdf $(NAME).html img/* *.lua

default: $(DISTFILES)

$(NAME).html: README.md
	awk -f grapho/md2html <$< >$@

$(NAME).tex: README.md
	awk -f grapho/md2tex <$< >$@

$(NAME).pdf: $(NAME).tex
	pdflatex $<
	pdflatex $<

$(NAME).zip: $(DISTFILES)
	zip $@ $(DISTFILES)

clean:
	rm -f *.html *.pdf *.tex *.aux *.log *.out *.zip
