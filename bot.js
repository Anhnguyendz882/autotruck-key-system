const {Client,GatewayIntentBits} = require("discord.js")
const fs = require("fs")

const client = new Client({
intents:[
GatewayIntentBits.Guilds,
GatewayIntentBits.GuildMessages,
GatewayIntentBits.MessageContent
]
})

const TOKEN = process.env.DISCORD_TOKEN

function randomKey(){

const chars=" MTQ1OTUyNDc5MjcwNDE3MjIxNQ.G8kmnW.mM0eOskBC9DM9D3BislsLV7GSmm6Kd1BCxOumE"

let key="AT-"

for(let i=0;i<20;i++){
key+=chars[Math.floor(Math.random()*chars.length)]
}

return key
}

client.on("messageCreate",msg=>{

if(msg.content.startsWith(".taokey")){

const args=msg.content.split(" ")

const player=args[1]

if(!player){
msg.reply("Usage: .taokey playername")
return
}

const key=randomKey()

const expire=Math.floor(Date.now()/1000)+(30*86400)

const data=JSON.parse(fs.readFileSync("keys.json"))

data.push({
key:key,
player:player,
expire:expire
})

fs.writeFileSync("keys.json",JSON.stringify(data,null,2))

msg.reply(`Key created for ${player}\nKey: ${key}`)
}

})

client.login(TOKEN)
