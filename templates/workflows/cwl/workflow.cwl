cwlVersion: v1.2
class: CommandLineTool
baseCommand: ["bash","-lc"]
inputs:
  message:
    type: string
    inputBinding:
      position: 1
      valueFrom: "echo $(inputs.message) > runs/primary/message.txt"
outputs:
  out:
    type: File
    outputBinding:
      glob: runs/primary/message.txt
