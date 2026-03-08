const express = require("express")
const fs = require("fs")
require("./bot")
const app = express()
app.use(express.json())

const DB = "./keydb.json"

function loadDB(){
    return JSON.parse(fs.readFileSync(DB))
}

function saveDB(data){
    fs.writeFileSync(DB, JSON.stringify(data,null,2))
}

app.get("/", (req,res)=>{
    res.sendFile(__dirname + "/index.html")
})

app.get("/check", (req,res)=>{

    const key = req.query.key
    const name = req.query.name

    if(!key || !name) return res.json({status:"error"})

    const db = loadDB()

    const found = db.keys.find(k=>k.key === key)

    if(!found)
        return res.json({status:"invalid"})

    if(found.name !== name)
        return res.json({status:"wrong_name"})

    res.json({
        status:"ok",
        name:found.name
    })
})

app.listen(process.env.PORT || 3000, ()=>{
    console.log("API KEY SYSTEM RUNNING")
})
