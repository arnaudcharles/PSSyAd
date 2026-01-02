function Invoke-ChocolateyAISGui(){
    <#
    .SYNOPSIS
        Print GUI to manage Chocolatey packages

    .DESCRIPTION
        Print GUI to manage Chocolatey packages

    .EXAMPLE
        Invoke-ChocolateyAISGui
    #>

    [CmdletBinding()]
    param()
    #make the dialog screen
    add-type -Assembly system.windows.forms
    $main_form = new-object system.windows.forms.form
    $main_form.text = 'Choco gui AIS.'
    $main_form.width = 600
    $main_form.height = 400
    $main_form.autosize = $true

    #make the first label and button
    $label = new-object System.Windows.forms.label
    $label.text = "Choco sources available:"
    $label.location = New-Object System.Drawing.Point(5,10)
    $label.autosize = $true
    $main_form.controls.add($label)

    $ComboBox_sourceList = New-Object System.Windows.Forms.ComboBox
    $ComboBox_sourceList.Width = 300
    [xml]$choco_conf = get-content C:\programdata\chocolatey\config\chocolatey.config
    Foreach ($source in $choco_conf.chocolatey.sources.source){
        $ComboBox_sourceList.Items.Add($source.id);
    }
        #default value in box
        $ComboBox_sourceList.Text = $ComboBox_sourceList.items[0]
    $ComboBox_sourceList.Location  = New-Object System.Drawing.Point(145,10)
    $main_form.Controls.Add($ComboBox_sourceList)

    #search button
    $Button = New-Object System.Windows.Forms.Button
    $Button.Location = New-Object System.Drawing.Size(5,60)
    $Button.Size = New-Object System.Drawing.Size(120,23)
    $Button.Text = "Search in source"
    $main_form.Controls.Add($Button)

    #output label and box
    $label_output = new-object system.windows.forms.label
    $label_output.text = 'Package list :'
    $label_output.location = New-Object System.Drawing.Point(5,110)
    $label_output.autosize = $true
    $main_form.controls.add($label_output)
    $ComboBox_packageList = New-Object System.Windows.Forms.ComboBox
    $ComboBox_packageList.Width = 300
    $ComboBox_packageList.Location  = New-Object System.Drawing.Point(145,110)
        #out default value in list
        choco search -s $ComboBox_sourceList.items[0] | ForEach-Object{$ComboBox_packageList.Items.add($_)}
        $ComboBox_packageList.Text = $ComboBox_packageList.items[1]
    $main_form.Controls.Add($ComboBox_packageList)



    #button action
    $Button.Add_Click(
        {
            $ComboBox_packageList.Items.clear()
            $textBox.text = "Searching for packages in the $($ComboBox_sourceList.selecteditem) source ..."
            choco search -s $ComboBox_sourceList.selecteditem | ForEach-Object{
                $ComboBox_packageList.Items.Add($_)
            }
            $ComboBox_packageList.Text = $ComboBox_packageList.items[1]
            $textBox.text = $ComboBox_packageList.Items
        }
    )

# Package selection and add to file

    #add install_application button
        $Button_install = New-Object System.Windows.Forms.Button
        $Button_install.Location = New-Object System.Drawing.Size(5,150)
        $Button_install.Size = New-Object System.Drawing.Size(160,23)
        $Button_install.Text = "Install selected package"
        $main_form.Controls.Add($Button_install)
    #add uninstall_application button
        $Button_uninstall = New-Object System.Windows.Forms.Button
        $Button_uninstall.Location = New-Object System.Drawing.Size(275,150)
        $Button_uninstall.Size = New-Object System.Drawing.Size(160,23)
        $Button_uninstall.Text = "Uninstall selected package"
        $main_form.Controls.Add($Button_uninstall)
    #output label and box
        $label_outputTextbox = new-object system.windows.forms.label
        $label_outputTextbox.text = 'Output :'
        $label_outputTextbox.location = New-Object System.Drawing.Point(5,180)
        $label_outputTextbox.autosize = $true
        $main_form.controls.add($label_outputTextbox)
        $textBox = new-object System.Windows.Forms.TextBox
        $textBox.text = "$($ComboBox_packageList.Items)"
        $textBox.location = New-Object System.Drawing.Point(5,210)
        $textBox.size = new-object system.Drawing.size(400,200)
        $textBox.multiline = $true
        $textBox.ScrollBars = 'vertical'
        $main_form.controls.add($textBox)


    #button action
    $Button_install.Add_Click(
        {
            $selectApp = ($ComboBox_packageList.selecteditem).split(' ')[0]

            $textBox.text = "Attempting to install $selectApp from $($ComboBox_sourceList.selecteditem) ..."
            $install = $(choco upgrade $selectApp -s "$($ComboBox_sourceList.selecteditem)" -y)
            $textBox.text = "$install"
        }
    )
    $Button_uninstall.Add_Click(
        {
            $textBox.text = "Attempting to uninstall $selectApp ..."
            $selectApp = ($ComboBox_packageList.selecteditem).split(' ')[0]
            $uninstall = $(choco uninstall $selectApp -y --force)
            $textBox.text = "$uninstall"
        }
    )

    $main_form.showdialog()
}