require 'nokogiri'
require 'rest_client'
require 'json'

FIELDS = ['country', 'name', 'full_location', 'website', 'coordinates', 'iasp_member', 'iasp_url', 'iasp_id', 'iasp_type', 'iasp_sectors']
BASE_URL = 'https://www.iasp.ws/our-members/directory/@'
APPEND_LOCATION = true

$records = {}
if APPEND_LOCATION
    f = open('snapshot_30072019.json').read
    data = JSON.parse(f)['records']
    data.each do |r|
        id = r['RecID'].to_i
        $records[id] = r
    end
end

def get_detail(url, id)
    res = RestClient.get(url)
    raw_page = res.body
    page = Nokogiri::HTML(raw_page)
    details = {
        country: nil,
        name: nil,
        full_location: nil,
        website: nil,
        coordinates: nil,
        iasp_member: 1,
        iasp_url: url,
        iasp_id: id,
        iasp_type: nil,
        iasp_sectors: nil
    }
    sectors = []
    page.css(".mergefield").each do |f|
        vdlabel = f.css(".vdlabel").text
        vdcon = f.css(".vdcontent").text
        if vdlabel.include?('Location')
            details[:full_location] = vdcon
            matches = vdcon.match(/(.*), (.*)/)
            if matches
                details[:country] = matches[2]
            end
        end
        if vdlabel.include?('Name') and details[:name] == nil
            details[:name] = vdcon
        end
        if vdlabel.include?('Website')
            website_anchor = f.css('.vdcontent a')
            if !website_anchor.empty?
                details[:website] = website_anchor.attr('href').value
            end
        end
        if vdlabel.include?('Type')
            details[:iasp_type] = vdcon
        end
        if vdlabel.include?('Main technology sectors')
            f.css('.vdcontent .vdcontent').each do |s|
                sectors << s.text.gsub("\t", "")
            end
        end

        if APPEND_LOCATION
            r = $records[id]
            latlng = r['Latitude'] + "," + r['Longitude']
            details[:coordinates] = latlng
        end
    end

    details[:iasp_sectors] = sectors.join(",")

    return details
end

# Taken from: https://www.iasp.ws/our-members/directory
page = Nokogiri::HTML(open("snapshot_30072019.html"))
members = page.css(".member-item")

members.each do |d|
    href = d.attr('href')
    splits = href.split('/')
    id = splits[3].gsub!("@", "").to_i
    url = BASE_URL + id.to_s
    name = d.css('.vdcontent').text.chomp.encode('utf-8')
    details = get_detail(url, id)
    puts details.values.join("\t")
end