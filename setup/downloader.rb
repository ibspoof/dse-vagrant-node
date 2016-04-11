require 'net/http'
require "uri"
require 'open-uri'

class Downloader

    @@installerDir = './installers/'
    @@baseUrl = "http://downloads.datastax.com/enterprise/"
    @@installName = "DataStaxEnterprise-[version]-linux-x64-installer.run"
    @@settings ||= {}
    @@dseSettings ||= {}

    # set base settings from config.yaml file
    def initialize(settings)
        @@settings = settings
        @@dseSettings = @@settings['vm']['dse']
    end

    # download DSE unattedned installer
    def downloadDSE()
        version = @@dseSettings['install']['version']

        installerFilename = @@installName.gsub("[version]", version)
        target = @@installerDir + installerFilename
        auto_download = @@dseSettings['install']['auto_download']

        if auto_download != true && !checkForInstaller(target)
            displayMsg("ERROR: auto_download is turned off and installer file <#{installerFilename}> does not exist." +
                       "\nPlease download unattended installer manually and place in installers directory. " +
                       "\nExiting. \n\n")
            exit!
        end

        if checkForInstaller(target)
            displayMsg("DSE Installer #{target} exists, skipping download")
            return
        end

        displayMsg("DSE Installer does not exist and auto_download enabled.")

        redirectUrl = @@baseUrl + installerFilename
        basicAuth = [ @@dseSettings['install']['username'], @@dseSettings['install']['password'] ]

        res = Net::HTTP.get_response(URI(redirectUrl))
        uri = res['location']

        displayMsg("Starting download of DSE Installer. This may take a while...")
        downloadFile(uri, target, basicAuth)
        displayMsg("Finished downloading DSE installer to #{target}")

        exit!
    end

    # Check if target for installer exists
    def checkForInstaller(target)
        return File.exist?(target)
    end

    # Download file from URI, authentication to target
    def downloadFile(uri, target, auth = nil, cookieHeader = nil)

        begin
            File.open(target, "wb") do |saved_file|
                if !cookieHeader
                    open(uri, :http_basic_authentication => auth) do |read_file|
                        saved_file.write(read_file.read)
                    end
                else
                    open(uri,
                         "Cookie" => cookieHeader,
                         :http_basic_authentication => auth) do |read_file|
                        saved_file.write(read_file.read)
                    end
                end
            end
        rescue OpenURI::HTTPError => error
            case error.io.status[0].to_i
                when 401
                    displayMsg("ERROR: Autentication failed, please check config.yaml username/password.")
                when 404
                    displayMsg("ERROR: Installer file not found, please check version number in config.yaml")
            end
            # delete opened file
            File.delete(target)
            exit!
        end

    end

    # Helper for displaying messages w/ newline
    def displayMsg(msg)
        puts "\n#{msg}"
    end


end
