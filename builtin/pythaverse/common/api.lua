function callFunction(url,method,headers,isExtra,body)
    minetest.log("callFunction with url:"..url)
    local http = core.get_http_api()
    
    if(isExtra) then
        minetest.log("1.extra:"..tostring(isExtra))
        local response = http.fetch_sync({ 
            url = url,
            method = method,
            extra_headers = headers,
            data = body
        })
       
        if response.succeeded then
            core.log(response.data)
            return  core.parse_json(response.data)
        end   

    else
        minetest.log("2.extra:"..tostring(isExtra))
        local response = http.fetch_sync({ 
            url = url,
            method = method,
            headers = headers,
            data = body
        })
        if response.succeeded then
            core.log(response.data)
            return  core.parse_json(response.data)
        end  
    end

  

    return {}
    
end

