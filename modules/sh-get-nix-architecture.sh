if [ -f /etc/redhat-release ] ; then
  PKGTYPE=rpm
elif [ -f /etc/system-release ] ; then
  PKGTYPE=rpm
else
  if uname -sv | grep 'Darwin' > /dev/null; then
    PKGTYPE=pkg
  else
    PKGTYPE=deb
  fi
fi
