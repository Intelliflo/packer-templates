$psake.use_exit_on_error = $true
properties {
  $baseDir = $psake.build_script_dir
}

Task default -depends Build-Packer, prepare-hyperv, convert-tovhd, package-hyperv


task build-packer {
  exec { packer build -force (Join-Path $baseDir vbox-2012r2.json) }
}

task prepare-hyperv {
    $vmPath = "$baseDir\hyper-v-output\Virtual Machines\vm.xml"
    [xml]$vmXml = Get-Content $vmPath
    $vmXml.configuration.properties.name.'#text' = '2012R2Min'
    $vmXml.Save($vmPath)

    $vboxDisk = Resolve-Path("$baseDir\output-virtualbox-iso\*.vmdk")
    $hyperVDir = "$baseDir\hyper-v-output\Virtual Hard Disks"
    if(!(Test-Path $hyperVDir)) { mkdir $hyperVDir }
    $hyperVDisk = Join-Path $hyperVDir 'disk.vhd'
    if(Test-Path $hyperVDisk) { Remove-Item $hyperVDisk -Force }
    $hyperVVagrantFile = "$baseDir\hyper-v-output\Vagrantfile"
    if(Test-Path $hyperVVagrantFile) { Remove-Item $hyperVVagrantFile -Force }
    Copy-Item (Join-Path $baseDir vagrantfile-windows.template) $hyperVVagrantFile
}

task convert-tovhd {
  $vboxDisk = Resolve-Path "$baseDir\output-virtualbox-iso\*.vmdk"
  $hyperVDir = "$baseDir\hyper-v-output\Virtual Hard Disks"
  $hyperVDisk = Join-Path $hyperVDir 'disk.vhd'
  ."$env:programfiles\oracle\VirtualBox\VBoxManage.exe" clonehd $vboxDisk $hyperVDisk --format vhd
}

task package-hyperv {
  ."$env:chocolateyInstall\tools\7za.exe" a -ttar (join-path $baseDir "$version-hyper-v.tar") (Join-Path $baseDir "hyper-v-output\*")
  ."$env:chocolateyInstall\tools\7za.exe" a -tgzip (join-path $baseDir "$version-hyper-v.box") (join-path $baseDir "$version-hyper-v.tar")
}

