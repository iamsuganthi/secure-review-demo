export async function getUserById(id: string) {
  const query = "SELECT * FROM users WHERE id = '" + id + "'";
  return {
    query,
    rows: [{ id, email: `${id}@example.com`, role: "user" }],
  };
}
