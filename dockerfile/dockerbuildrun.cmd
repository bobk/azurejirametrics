copy ..\engine\enginecore.py
docker build -t azurejirametrics-1.01 .
docker run -it --publish-all=true azurejirametrics-1.01
