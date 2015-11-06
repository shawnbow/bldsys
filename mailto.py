#!/usr/bin/env python
# -*- coding: UTF-8 -*-
'''
Mailto: Subject, Content, Attatchment
'''
import sys
import smtplib  
from email.mime.text import MIMEText  
from email.mime.multipart import MIMEMultipart

msg = MIMEMultipart()

mailto_list=["zhen.bao@acadine.com"]
mail_host="smtp.exmail.qq.com"  #SMTP server
mail_user="it@infthink.com"     #User
mail_pass="infthink2014"        #Password
me="Build Daemon"+"<"+mail_user+">"

def send_mail(to_list, sub, content=None, att_path=None):
    
    if (att_path != None):
        att1 = MIMEText(open(att_path, 'rb').read(), 'base64', 'utf8')
        att1["Content-Type"] = 'application/octet-stream'
        att1["Content-Disposition"] = 'attachment; filename="part_error.log"'#这里的filename可以任意写，写什么名字，邮件中显示什么名字
        msg.attach(att1)

    if (content != None):
        att2 = MIMEText(content, _subtype='plain', _charset='utf8')
        msg.attach(att2)

    msg['subject'] = sub
    msg['from'] = me
    msg['to'] = ";".join(to_list)
    try:  
        server = smtplib.SMTP()
        server.connect(mail_host)
        server.login(mail_user,mail_pass)
        server.sendmail(me, to_list, msg.as_string())
        server.close()
        return True
    except Exception, e:
        print str(e)
        return False

if __name__ == '__main__':
    argc = len(sys.argv)
    if argc == 2:
        result = send_mail(mailto_list, sys.argv[1])
    elif argc == 3:
        result = send_mail(mailto_list, sys.argv[1], sys.argv[2])
    elif argc == 4:
        result = send_mail(mailto_list, sys.argv[1], sys.argv[2], sys.argv[3])

    if result:
        print "Sent Successfully!"  
    else:  
        print "Sent Failed!!!"
