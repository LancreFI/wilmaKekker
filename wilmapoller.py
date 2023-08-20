# coding=iso-8859-15
import requests, re, argparse, click, sys, urllib.parse
from argparse import RawTextHelpFormatter
from getpass import getpass

wilma_url = "https://helsinki.inschool.fi"
wilma_user_agent = "Wilmap0ller v0.1A"


class color:
    red = '\033[91m'
    gre = '\033[92m'
    yel = '\033[93m'
    blu = '\033[94m'
    rst = '\033[0m'
    synth_yel = '\033[38;5;220m'
    synth_ora = '\033[38;5;208m'
    synth_red = '\033[38;5;197m'
    synth_pin = '\033[38;5;201m'
    synth_pur = '\033[38;5;128m'
    synth_blu = '\033[38;5;56m'
    synth_cya = '\033[38;5;49m'


class wilma_session:
    def __init__(wilma):
        wilma.session = requests.Session()
        wilma.session.get(f"{wilma_url}/login")
        wilma.session_id = str(wilma.session.cookies['Wilma2LoginID'])
        wilma.user_agent = wilma_user_agent


    def login(wilma, username, password):
        wilma.user = username
        wilma.password = password
        wilma.session.auth = (wilma.user, wilma.password)
        login_rawdata = f"Login={urllib.parse.quote_plus(wilma.user)}"\
            f"&Password={urllib.parse.quote_plus(wilma.password)}"\
            f"&submit={urllib.parse.quote_plus('Kirjaudu sisään')}"\
            f"&SESSIONID={wilma.session_id}&returnpath="
        login_headers = { 'content-type': 'application/x-www-form-urlencoded',
            'cookie': 'Wilma2LoginID=' + wilma.session_id,
            'user-agent': wilma.user_agent,
            'origin': wilma_url,
            'referer': wilma_url + '/login' }
        wilma.login = wilma.session.post(f"{wilma_url}/login", headers=login_headers, data=login_rawdata)
        wilma.sid = str(wilma.session.cookies['Wilma2SID'])
        wilma.formkey = (re.search('formkey" value="(passwd:[\d]{5}:[\w]{32})', str(wilma.login.content)).group(1))


    def logout(wilma):
        logout_rawdata = f"formkey={urllib.parse.quote_plus(wilma.formkey)}"
        logout_headers = { 'content-type':'application/x-www-form-urlencoded',
            'cookie': 'Wilma2SID=' + wilma.sid,
            'user-agent': wilma_user_agent,
            'origin': wilma_url,
            'referer': wilma_url + '/' }
        wilma.logout = wilma.session.post(f"{wilma_url}/logout", headers=logout_headers, data=logout_rawdata)


    def get_roles(wilma):
        wilma.roles_response = wilma.session.get(f"{wilma_url}/api/v1/accounts/me/roles")
        wilma.roles = wilma.roles_response.json()
        wilma.users = {}
        for user in wilma.roles['payload']:
            wilma.users[user['name']] = {}
            wilma.users[user['name']]['type'] = user['type']
            wilma.users[user['name']]['primusId'] = user['primusId']
            wilma.users[user['name']]['formKey'] = user['formKey']
            wilma.users[user['name']]['slug'] = user['slug']
            for school in user['schools']:
                wilma.users[user['name']]['school'] = school
        return wilma.users


    def get_lastlogin(wilma):
        wilma.lastlogin_response = wilma.session.get(f"{wilma_url}/api/v1/accounts/me/latestlogin")
        wilma.lastlogin_json = wilma.lastlogin_response.json()
        return (wilma.lastlogin_json['payload'])


    def get_guardianinfo(wilma):
        wilma.guardian_response = wilma.session.get(f"{wilma_url}/api/v1/accounts/me")
        wilma.guardian_json = wilma.guardian_response.json()
        return (wilma.guardian_json['payload'])


##MAIN
if __name__ == '__main__':
    try:
        BANNER = """
        """+color.synth_blu+""" #####################################################
        """+color.synth_cya+""" #######   ###  ####  ###  ###     ##     ##      ####
        """+color.synth_pur+""" ######   ###    ###   ##  #   ###  #  ##  #  ########
        """+color.synth_pin+""" #####   ###  ##  ##    #  #  #######  #  ##     #####
        """+color.synth_red+""" ####   ###  #  #  #  #    #   ###  #  ##  #  ########
        """+color.synth_ora+""" #### fi     ####     ##   ###     ##  ###        ####
        """+color.synth_yel+""" #####################################################
        """+color.rst+"""
                     .--------------------------.
                     |    Wilma p0ller v0.1A    |
                     '--------------------------'
                     .--------------------------.
                     | Just for keks, and       |
                     | due to having multiple   |
                     | kids and Wilma UI being  |
                     | just horrible.           |
                     '--------------------------'
        """

        parser = argparse.ArgumentParser(
            prog='Wilma Poller',
            description=BANNER,
            formatter_class=RawTextHelpFormatter,
            epilog=f"{color.synth_cya}n00t n00t{color.rst}")

        parser.add_argument('--roles',
            help='Use this argument if you want to view your roles in Wilma',
            action='store_true')
        parser.add_argument('--lastlogin',
            help='Use this argument if you want to view your last Wilma login time',
            action='store_true')
        parser.add_argument('--info',
            help='Use this argument if you want to view the guardian info',
            action='store_true')
        args = parser.parse_args()

        print (f"\n{color.gre}Starting Wilma poller...{color.rst}")
        wilma_user = input(f" {color.blu}Wilma username:{color.rst} ")
        wilma_pass = getpass(f" {color.blu}Wilma password:{color.rst} ")
        poller_session = wilma_session()
        poller_session.login(wilma_user, wilma_pass)

        if args.roles:
            users = poller_session.get_roles()
            print (users)

        if args.lastlogin:
            lastlogin = poller_session.get_lastlogin()
            print (lastlogin)

        if args.info:
            guardian_info = poller_session.get_guardianinfo()
            print (guardian_info)

        poller_session.logout()

    except Exception as err:
        print (f"{color.red}Something borked!\n{color.rst}")
        try:
            poller_session.logout()
        except:
            sys.exit(f"{color.red}Auto logout failed!{color.rst}\n")
        sys.exit(f"\n{err}\n")
