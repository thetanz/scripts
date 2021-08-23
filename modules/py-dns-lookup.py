import dns.resolver

def get_records(domain):
    ids = [
        'SOA',
        'TXT',
        'AAAA',
        'CAA',
    ]

    for a in ids:
        try:
            answers = dns.resolver.query(domain, a)
            for rdata in answers:
                print(a, ':', rdata.to_text())
        except Exception as e:
            print(e)

get_records('theta.co.nz')
