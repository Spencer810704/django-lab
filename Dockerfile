# Base Image
FROM python:3.9-alpine

# 安裝編譯工具
RUN apk add alpine-sdk openssl-dev libffi-dev postgresql-dev git openssh tzdata openssl

# 升級pip工具
RUN /usr/local/bin/python3 -m pip install --upgrade pip

# 安裝專案所需library
COPY requirements.txt /requirements.txt
RUN pip install -r /requirements.txt

# 移除編譯工具(減少image使用空間)
RUN apk del alpine-sdk openssl-dev libffi-dev

# 複製整個Application到容器內
COPY app /app

# 設定工作根目錄在/app
WORKDIR /app


ENTRYPOINT ["python", "manage.py", "runserver"]
CMD ["0.0.0.0:80"]