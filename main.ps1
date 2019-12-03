##pete.endacott@gmail.com - 2019
Import-Module PSGSuite

$users = Get-GSUser -Filter "@contoso.com"
$excluded = Get-Content "C:\ProgramData\AutoTech\2FA-Nag\excluded.txt"

$alerts = "C:\Test\notify.txt"


###Email Settings
$SqlSMTPU = "SELECT w.Value From [SQL\ATSQL].[at-config].[dbo].[config_settings] w Where w.Setting = 'ATsmtpU'"
$SqlSMTPP = "SELECT w.Value From [SQL\ATSQL].[at-config].[dbo].[config_settings] w Where w.Setting = 'ATsmtpP'"
$v1 = Invoke-sqlcmd -Query $SqlSMTPU -ServerInstance "SQL\ATSQL"
$v2 = Invoke-sqlcmd -Query $SqlSMTPP -ServerInstance "SQL\ATSQL"
$Username = $v1.Value
$Password = $v2.Value
$SMTPServer = "smtp.gmail.com"
$SMTPPort = "587"

$naughtyList =@()

foreach($user in $users){
    if($user.Suspended -eq $false -And $user.IsEnrolledIn2Sv -eq $false -And $excluded -notcontains $user.user){
                    $notifyUser = $user.user
                    #$notifyUser | Out-File -FilePath C:\Test\notify.txt -Append

                    ##Check if username exists in Database
                    $SQLDBCheck = "SELECT w.username From [SQL\ATSQL].[2fa-nag].[dbo].[nag-count] w Where CONVERT(VARCHAR, [username]) = '$notifyuser'"
                    $DBCheck = Invoke-sqlcmd -Query $SQLDBCheck -ServerInstance "SQL\ATSQL"

                    if($DBCheck -ne $Null){ ##If username already exists in database
                        
                        $getCount = "SELECT w.count From [SQL\ATSQL].[2fa-nag].[dbo].[nag-count] w Where CONVERT(VARCHAR, [username]) = '$notifyuser'"
                        $countValue = Invoke-sqlcmd -Query $getCount -ServerInstance "SQL\ATSQL"

                        $newCount = $countValue.count + 1

                                if($newCount -gt 3){
                                    $naughtyList += $notifyUser
                                                    }
                                else{
                                    ###email
                                    $to = "pete.endacott@gmail.com"#$notifyUser
                                    $cc = "pete.endacott@gmail.com"
                                    $subject = "IMPORTANT - Please setup 2FA on your Google Account!"
                                    $body = Get-Content ("C:\ProgramData\AutoTech\2FA-Nag\EmailTemplate.html")
                                    $outgoingEmail = "autotech@contoso.com"

                                    $message = New-Object System.Net.Mail.MailMessage
                                    $message.subject = $subject
                                    $message.body = $body
                                    $message.to.add($to)
                                    $message.cc.add($cc)
                                    $message.from = $outgoingEmail
                                    $message.IsBodyHtml = $True

                                    $smtp = New-Object System.Net.Mail.SmtpClient($SMTPServer, $SMTPPort);
                                    $smtp.EnableSSL = $true
                                    $smtp.Credentials = New-Object System.Net.NetworkCredential($Username, $Password);
                                    $smtp.send($message)
                                    ####################
                                   }
                                                                   
                        ##WriteToTable
                        $Syncquery=@"
                        UPDATE [SQL\ATSQL].[2fa-nag].[dbo].[nag-count]
                               SET [count] = '$newCount'
                               WHERE CONVERT(VARCHAR, [username]) = '$notifyUser'
"@
                        Invoke-SQLcmd -ServerInstance 'SQL\ATSQL' -query $Syncquery
                        }
                        else{##if user does not exist in database

                        ###define email here
                                    $to = "pete.endacott@gmail.com"#$notifyUser
                                    $cc = "pete.endacott@gmail.com"
                                    $subject = "IMPORTANT - Please setup 2FA on your Google Account!"
                                    $body = Get-Content ("C:\ProgramData\AutoTech\2FA-Nag\EmailTemplate.html")
                                    $outgoingEmail = "autotech@contoso.com"

                                    $message = New-Object System.Net.Mail.MailMessage
                                    $message.subject = $subject
                                    $message.body = $body
                                    $message.to.add($to)
                                    $message.cc.add($cc)
                                    $message.from = $outgoingEmail
                                    $message.IsBodyHtml = $True

                                    $smtp = New-Object System.Net.Mail.SmtpClient($SMTPServer, $SMTPPort);
                                    $smtp.EnableSSL = $true
                                    $smtp.Credentials = New-Object System.Net.NetworkCredential($Username, $Password);
                                    $smtp.send($message)



                        ####################

                    
                        $insertquery=" 
                        INSERT INTO [SQL\ATSQL].[2fa-nag].[dbo].[nag-count] 
                        ([username] 
                        ,[count]) 
                        VALUES 
                        ('$notifyUser' 
                        ,'1') 
                        GO 
                        " 

                        Invoke-SQLcmd -ServerInstance 'SQL\ATSQL' -query $insertquery
                        }

              }
 }

if($naughtyList -ne $null){
###define naughty email
}
