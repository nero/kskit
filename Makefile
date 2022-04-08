NAME=KsKit

default: $(NAME).html $(NAME).pdf

$(NAME).html: README.md
	awk -f grapho/md2html <$< >$@

$(NAME).tex: README.md
	awk -f grapho/md2tex <$< >$@

$(NAME).pdf: $(NAME).tex
	pdflatex $<
	pdflatex $<

clean:
	rm -f *.html *.pdf *.tex *.aux *.log *.out
