#!/usr/bin/python

import hashlib, argparse

def main():
    parser = argparse.ArgumentParser(description = 'Get your hash for gravatar.')
    parser.add_argument('-e', '--email', help = 'Email', required = True)
    parser.add_argument('-s', '--size', help = 'Size of the image', required = True)
    args = parser.parse_args()

    gravatar_url = "http://www.gravatar.com/avatar/" + \
            hashlib.md5(args.email.lower()).hexdigest() + \
            ".png?s=" + \
            args.size
    return gravatar_url

if __name__ == "__main__":
    print main()
