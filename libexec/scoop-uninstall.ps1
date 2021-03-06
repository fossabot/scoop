# Usage: scoop uninstall <app> [options]
# Summary: Uninstall an app
# Help: e.g. scoop uninstall git

. "$($MyInvocation.MyCommand.Path | Split-Path | Split-Path)\lib\core.ps1"
. $(rootrelpath "lib\manifest.ps1")
. $(rootrelpath "lib\help.ps1")
. $(rootrelpath "lib\install.ps1")
. $(rootrelpath "lib\versions.ps1")
. $(rootrelpath "lib\getopt.ps1")

reset_aliases

if(!$args) { 'ERROR: <app> missing'; my_usage; exit 1 }

if ($null -ne $args) { $args | foreach-object {
    $app = $_

    if($app -eq 'scoop') {
        & $(rootrelpath "bin\uninstall.ps1") $global; exit
    }

    $global = installed $app $true
    if($global -and !(is_admin)) {
        'ERROR: you need admin rights to disable global apps'; exit 1
    }

    $version = current_version $app $global
    "uninstalling $app ($version)"

    $dir = versiondir $app $version $global
    try {
        test-path $dir -ea stop | out-null
    } catch [unauthorizedaccessexception] {
        abort "access denied: $dir. you might need to restart"
    }

    $manifest = installed_manifest $app $version $global
    $install = install_info $app $version $global
    $architecture = $install.architecture

    run_uninstaller $manifest $architecture $dir
    rm_shims $manifest $global
    env_rm_path $manifest $dir $global
    env_rm $manifest $global


    try { remove-item -r $dir -ea stop -force }
    catch { abort "couldn't remove $(friendly_path $dir): it may be in use" }

    # remove older versions
    $old = @(versions $app $global)
    if ($null -ne $old) { foreach ($oldver in $old) {
        "removing older version, $oldver"
        $dir = versiondir $app $oldver $global
        try { remove-item -r -force -ea stop $dir }
        catch { abort "couldn't remove $(friendly_path $dir): it may be in use" }
    }}

    if(@(versions $app).length -eq 0) {
        $appdir = appdir $app $global
        try {
            # if last install failed, the directory seems to be locked and this
            # will throw an error about the directory not existing
            remove-item -r $appdir -ea stop -force
        } catch {
            if((test-path $appdir)) { throw } # only throw if the dir still exists
        }
    }

    success "$app was uninstalled"
}}

exit 0
