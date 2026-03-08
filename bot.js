const { Client, GatewayIntentBits } = require("discord.js")
const fs = require("fs")

const TOKEN = process.env.DISCORD_TOKEN
const CHANNEL_ID = process.env.LOG_CHANNEL

const client = new Client({
  intents:[
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent
  ]
})

const DB="keys.json"

if(!fs.existsSync(DB)){
  fs.writeFileSync(DB,JSON.stringify({}))
}

function generateKey(){

  const chars="ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  let key="AT-"

  for(let i=0;i<10;i++){
    key+=chars[Math.floor(Math.random()*chars.length)]
  }

  return key
}

client.once("ready",()=>{

  console.log("BOT ONLINE:",client.user.tag)

  setInterval(checkExpire,60000)

})

client.on("messageCreate",msg=>{

  if(msg.author.bot) return

  if(!msg.content.startsWith(".taokey")) return

  const args=msg.content.split(" ")

  if(args.length<3){
    return msg.reply("dùng: .taokey ingame days")
  }

  const ingame=args[1]
  const days=parseInt(args[2])

  if(isNaN(days)){
    return msg.reply("days phải là số")
  }

  const key=generateKey()

  const expire=Date.now()+days*86400000

  const data=JSON.parse(fs.readFileSync(DB))

  data[key]={
    user:ingame,
    expire:expire,
    hwid:null
  }

  fs.writeFileSync(DB,JSON.stringify(data,null,2))

  msg.reply(
`KEY CREATED

User: ${ingame}
Key: ${key}
Days: ${days}`
)

})

function checkExpire(){

  const data=JSON.parse(fs.readFileSync(DB))
  let changed=false

  for(const key in data){

    if(Date.now()>data[key].expire){

      const user=data[key].user
      delete data[key]

      const channel=client.channels.cache.get(CHANNEL_ID)

      if(channel){
        channel.send(`Key ${key} của ${user} đã hết hạn và bị xóa`)
      }

      changed=true
    }

  }

  if(changed){
    fs.writeFileSync(DB,JSON.stringify(data,null,2))
  }

}

client.login(TOKEN)
