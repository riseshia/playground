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

  try {
    await Projects.deleteByName(projectName)

    return Response.json({ data: { status: 'ok' } })
  } catch (e: any) {
    return Response.json({ error: e.message })
  }
}
