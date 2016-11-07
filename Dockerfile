FROM scratch
LABEL databox.type="driver"
COPY main.native /home/tc/main.native
ENTRYPOINT [ "/home/tc/main.native" ]
EXPOSE 8080
