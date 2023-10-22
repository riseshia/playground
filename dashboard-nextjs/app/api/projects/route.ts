import { Projects } from '../../models/Projects'

export async function GET() {
  try {
    const projects = await Projects.all()

    return Response.json({ data: { projects } })
  } catch (e: any) {
    return Response.json({ error: e.message })
  }
}

export async function DELETE(request: Request) {
  const params = await request.json()
  const projectName = params.name

  return Response.json({ data: { status: 'ok' } })
  // try {
  //   const projects = fetchProjectsFromDocker()
  //   const project = projects.find((project: Project) => {
  //     return project.name === projectName
  //   })
  //
  //   if (project && project.configPath) {
  //     startProject(project.configPath)
  //     return Response.json({ data: { status: 'ok' } })
  //   } else {
  //     return Response.json({ error: 'project not found' })
  //   }
  //
  // } catch (e: any) {
  //   return Response.json({ error: e.message })
  // }
}
