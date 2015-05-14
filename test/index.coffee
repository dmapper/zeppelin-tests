WebSocket = require 'ws'
uuid = require 'uuid'

chai = require 'chai'
chai.should()

expect = chai.expect

dump = (obj) ->
  console.log JSON.stringify obj, null, 2


describe 'Zeppline', ->

  ws = null
  noteId = null
  note = null


  it 'Should connect to zeppelin', (done)->
    ws = new WebSocket('ws://localhost:8081/')
#    ws = new WebSocket('ws://archimedes.ompnt.com:7576/')

    ws.sendMessage = (op, data)->
      obj = {op}
      obj.data = data if data?
      @send(JSON.stringify(obj))

    ws.extractMessage = (event)->
      msg = {};
      try
        msg = JSON.parse(event.data)

      msg

    ws.on 'open', ->
      done()

    ws.onclose = -> console.log 'close'
    ws.onerror = -> console.log 'error'


  it 'Should get notes list', (done)->
    ws.sendMessage 'LIST_NOTES'

    ws.onmessage = (event) ->

      msg = ws.extractMessage(event)
      if msg.op is 'NOTES_INFO'
        expect(msg?.data).to.exist
        expect(msg?.data?.notes).to.exist
        expect(msg?.data?.notes).to.be.an('array')
        expect(msg?.data?.notes?.length).to.be.at.least(0)
        done()


  it 'Should create a note', (done)->
    noteId = uuid.v1()
    ws.sendMessage 'NEW_NOTE', id: noteId

    ws.onmessage = (event) ->

      msg = ws.extractMessage(event)
      if msg.op is 'NOTES_INFO'
        found = false
        notes = (msg?.data?.notes || [])

        for n in notes
          if n.id is noteId then found = true

        found.should.eql(true)
        done()

  it 'Should get a note', (done)->

    ws.sendMessage 'GET_NOTE', id: noteId

    ws.onmessage = (event) ->

      msg = ws.extractMessage(event)


      if msg.op is 'NOTE'
        expect(msg?.data).to.exist
        expect(msg?.data?.note).to.exist
        expect(msg?.data?.note.paragraphs).to.be.an('array')
        expect(msg?.data?.note.paragraphs?.length).to.be.at.least(1)

        note = msg?.data?.note || {}

        done()


  it 'Should run a paraghaph', (done)->

    ws.sendMessage 'RUN_PARAGRAPH',
      id: note.paragraphs[0].id
      title: 'Hello paragraph'
      params: {}
      config: {}
      paragraph: "%md \n ## Hello world "

    ws.onmessage = (event) ->

      msg = ws.extractMessage(event)

      if msg.op is 'NOTE'
        note = msg?.data?.note || {}
        paragraph = note.paragraphs[0]

        if paragraph.status is "FINISHED"
          paragraph?.result?.msg.should.eql("<h2>Hello world</h2>\n")
          done()

  it 'Should be able to delete a note', (done)->

    ws.sendMessage 'DEL_NOTE', id: noteId

    ws.onmessage = (event) ->

      msg = ws.extractMessage(event)
      if msg.op is 'NOTES_INFO'

        found = false
        notes = (msg?.data?.notes || [])

        for n in notes
          if n.id is noteId then found = true

        found.should.not.eql(true)
        done()
