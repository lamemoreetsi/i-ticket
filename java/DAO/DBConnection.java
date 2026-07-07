package DAO;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.SQLException;

public class DBConnection {
    private static DataSource dataSource = null;

    static {
        try {
            // Standard approach to cleanly fetch environment contexts in Tomcat
            Context initContext = new InitialContext();
            Context envContext  = (Context) initContext.lookup("java:comp/env");
            dataSource = (DataSource) envContext.lookup("jdbc/ITICKET");
        } catch (NamingException e) {
            System.err.println("CRITICAL: DBConnection lookup failed!");
            e.printStackTrace();
        }
    }

    public static Connection getConnection() throws SQLException {
        if (dataSource == null) {
            throw new SQLException("DataSource could not be initialized from context.xml");
        }
        return dataSource.getConnection();
    }
}