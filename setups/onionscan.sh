# https://github.com/s-rah/onionscan/issues/174

sudo apt-get install tor bison libexif-dev python-pip -y
pip install stem
bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
[[ -s "${HOME}/.gvm/scripts/gvm" ]] && source "${HOME}/.gvm/scripts/gvm"
source ${HOME}/.gvm/scripts/gvm
gvm install go1.4
gvm use go1.4
go get github.com/HouzuoGuo/tiedot
go get golang.org/x/crypto/openpgp
go get golang.org/x/net/proxy
go get golang.org/x/net/html
go get github.com/rwcarlsen/goexif/exif
go get github.com/rwcarlsen/goexif/tiff
go get github.com/s-rah/onionscan
go install github.com/s-rah/onionscan
echo "ControlPort 9051" >> /etc/tor/torrc
echo "ControlListenAddress 127.0.0.1" >> /etc/tor/torrc
sudo service tor restart
