# lavalink install script

Usage:

```bash
 wget https://raw.githubusercontent.com/phillychi3/lavalink-install/main/install.sh
 chmod +x install.sh
 ./install.sh
```


```bash
./install.sh -p 23333 -pwd setpassword -sid spotify_client_id -scs spotify_client_screct
```

update

```bash
./install.sh -u
```

check log

```bash
sudo journalctl -u lavalink
```

other

```bash
sudo systemctl start lavalink
sudo systemctl restart lavalink
sudo systemctl stop lavalink
```
