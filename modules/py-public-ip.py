def is_public_ip(ip):
        ip = list(map(int, ip.strip().split('.')[:2]))
        if ip[0] == 10: return False
        if ip[0] == 172 and ip[1] in range(16, 32): return False
        if ip[0] == 192 and ip[1] == 168: return False
        return True
