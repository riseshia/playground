import { Projects } from '../../../models/Projects'

export async function POST(request: Request) {
  try {
    const params = await request.json()
    const projectName = params.name

    const project = await Projects.findByName(projectName)

    if (project && project.configPath) {
      Projects.restart(project)
      return Response.json({ data: { status: 'ok' } })
    } else if (project) {
      return Response.json({ error: `project '${projectName}' found, but don't know where it is` })
    } else {
      return Response.json({ error: `project '${projectName}' not found` })
    }
  } catch (e: any) {
    return Response.json({ error: e.message })
  }
}
