const { Client, GatewayIntentBits } = require("discord.js")
const fs = require("fs")

const client = new Client({
    intents:[GatewayIntentBits.Guilds, GatewayIntentBits.GuildMessages, GatewayIntentBits.MessageContent]
})

const TOKEN = process.env.TOKEN

const DB = "./keydb.json"

function loadDB(){
    return JSON.parse(fs.readFileSync(DB))
}

function saveDB(data){
    fs.writeFileSync(DB, JSON.stringify(data,null,2))
}

function randomKey(){

    const chars="ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

    let k="KEY-"

    for(let i=0;i<20;i++)
        k+=chars[Math.floor(Math.random()*chars.length)]

    return k
}

client.on("messageCreate", msg=>{

    if(msg.author.bot) return

    if(msg.content.startsWith(".taokey")){

        const name = msg.content.split(" ")[1]

        if(!name)
            return msg.reply("❌ dùng: `.taokey ten_ingame`")

        const key = randomKey()

        const db = loadDB()

        db.keys.push({
            key:key,
            name:name,
            created:Date.now()
        })

        saveDB(db)

        msg.reply(
`✅ Đã tạo key

👤 Name: ${name}
🔑 Key: ${key}

⚠️ Chỉ name này mới dùng được`
        )
    }
})

client.login(TOKEN)
