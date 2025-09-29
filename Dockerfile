FROM python:3.14-rc-alpine

WORKDIR /usr/src/app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

CMD ["mkdocs", "serve"]

EXPOSE 8000
